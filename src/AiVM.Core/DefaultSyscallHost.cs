using System.Net;
using System.Net.Http;
using System.Net.Security;
using System.Net.Sockets;
using System.Security.Authentication;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Diagnostics;
using System.Text;
using System.Runtime.InteropServices;
using System.Globalization;
using System.ComponentModel;
using System.Threading;

namespace AiVM.Core;

public partial class DefaultSyscallHost : ISyscallHost
{
    private static readonly HttpClient HttpClient = new();
    private static readonly string[] EmptyArgv = Array.Empty<string>();
    private static readonly Stopwatch MonotonicStopwatch = Stopwatch.StartNew();
    private int _nextUiHandle = 1;
    private readonly HashSet<int> _openWindows = new();
    private readonly Dictionary<int, Stack<UiTransform2D>> _uiTransformStacks = new();
    private readonly LinuxX11UiBackend? _linuxUi = OperatingSystem.IsLinux() ? new LinuxX11UiBackend() : null;
    private readonly WindowsWin32UiBackend? _windowsUi = OperatingSystem.IsWindows() ? new WindowsWin32UiBackend() : null;
    private readonly MacOsScriptUiBackend? _macUi = OperatingSystem.IsMacOS() ? new MacOsScriptUiBackend() : null;

    public virtual string[] ProcessArgv() => EmptyArgv;

    public virtual int TimeNowUnixMs() => unchecked((int)DateTimeOffset.UtcNow.ToUnixTimeMilliseconds());

    public virtual int TimeMonotonicMs() => unchecked((int)MonotonicStopwatch.ElapsedMilliseconds);

    public virtual void TimeSleepMs(int ms) => Thread.Sleep(ms);

    public virtual void ConsoleWriteErrLine(string text) => Console.Error.WriteLine(text);

    public virtual void ConsoleWrite(string text) => Console.Write(text);

    public virtual string ProcessCwd() => Directory.GetCurrentDirectory();

    public virtual string ProcessEnvGet(string name) => Environment.GetEnvironmentVariable(name) ?? string.Empty;

    public virtual void ConsolePrintLine(string text) => Console.WriteLine(text);

    public virtual void IoPrint(string text) => Console.WriteLine(text);

    public virtual void IoWrite(string text) => Console.Write(text);

    public virtual string IoReadLine() => Console.ReadLine() ?? string.Empty;

    public virtual string IoReadAllStdin() => Console.In.ReadToEnd();

    public virtual string IoReadFile(string path) => File.ReadAllText(path);

    public virtual bool IoFileExists(string path) => File.Exists(path);

    public virtual bool IoPathExists(string path) => File.Exists(path) || Directory.Exists(path);

    public virtual void IoMakeDir(string path) => Directory.CreateDirectory(path);

    public virtual void IoWriteFile(string path, string text) => File.WriteAllText(path, text);

    public virtual string FsReadFile(string path) => File.ReadAllText(path);

    public virtual bool FsFileExists(string path) => File.Exists(path);

    public virtual string[] FsReadDir(string path)
    {
        if (!Directory.Exists(path))
        {
            return Array.Empty<string>();
        }

        return Directory
            .GetFileSystemEntries(path)
            .Select(Path.GetFileName)
            .Where(name => !string.IsNullOrEmpty(name))
            .Cast<string>()
            .ToArray();
    }

    public virtual VmFsStat FsStat(string path)
    {
        if (File.Exists(path))
        {
            var fileInfo = new FileInfo(path);
            return new VmFsStat(
                "file",
                unchecked((int)fileInfo.Length),
                unchecked((int)new DateTimeOffset(fileInfo.LastWriteTimeUtc).ToUnixTimeMilliseconds()));
        }

        if (Directory.Exists(path))
        {
            var directoryInfo = new DirectoryInfo(path);
            return new VmFsStat(
                "dir",
                0,
                unchecked((int)new DateTimeOffset(directoryInfo.LastWriteTimeUtc).ToUnixTimeMilliseconds()));
        }

        return new VmFsStat("missing", 0, 0);
    }

    public virtual bool FsPathExists(string path) => File.Exists(path) || Directory.Exists(path);

    public virtual void FsWriteFile(string path, string text) => File.WriteAllText(path, text);

    public virtual void FsMakeDir(string path) => Directory.CreateDirectory(path);

    public virtual int StrUtf8ByteCount(string text) => Encoding.UTF8.GetByteCount(text);

    public virtual string CryptoBase64Encode(string text) => Convert.ToBase64String(Encoding.UTF8.GetBytes(text));

    public virtual string CryptoBase64Decode(string text)
    {
        try
        {
            return Encoding.UTF8.GetString(Convert.FromBase64String(text));
        }
        catch
        {
            return string.Empty;
        }
    }

    public virtual string CryptoSha1(string text)
    {
        var hash = SHA1.HashData(Encoding.UTF8.GetBytes(text));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }

    public virtual string CryptoSha256(string text)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(text));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }

    public virtual string CryptoHmacSha256(string key, string text)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(key));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(text));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }

    public virtual string CryptoRandomBytes(int count)
    {
        if (count <= 0)
        {
            return string.Empty;
        }

        var bytes = new byte[count];
        RandomNumberGenerator.Fill(bytes);
        return Convert.ToBase64String(bytes);
    }

    public virtual string HttpGet(string url)
    {
        try
        {
            var normalizedUrl = url.Replace(" ", "%20", StringComparison.Ordinal);
            return HttpClient.GetStringAsync(normalizedUrl).GetAwaiter().GetResult();
        }
        catch
        {
            return string.Empty;
        }
    }

    public virtual string Platform()
    {
        if (OperatingSystem.IsMacOS())
        {
            return "macos";
        }

        if (OperatingSystem.IsWindows())
        {
            return "windows";
        }

        if (OperatingSystem.IsLinux())
        {
            return "linux";
        }

        return "unknown";
    }

    public virtual string Architecture()
    {
        return RuntimeInformation.OSArchitecture.ToString().ToLowerInvariant();
    }

    public virtual string OsVersion()
    {
        return RuntimeInformation.OSDescription;
    }

    public virtual string Runtime()
    {
        return "airun-dotnet";
    }

    public virtual int NetListen(VmNetworkState state, int port)
    {
        var listener = new TcpListener(IPAddress.Loopback, port);
        listener.Start();
        var handle = state.NextNetHandle++;
        state.NetListeners[handle] = listener;
        return handle;
    }

    public virtual int NetListenTls(VmNetworkState state, int port, string certPath, string keyPath)
    {
        X509Certificate2 certificate;
        try
        {
            certificate = X509Certificate2.CreateFromPemFile(certPath, keyPath);
        }
        catch
        {
            return -1;
        }

        var listener = new TcpListener(IPAddress.Loopback, port);
        listener.Start();
        var handle = state.NextNetHandle++;
        state.NetListeners[handle] = listener;
        state.NetTlsCertificates[handle] = certificate;
        return handle;
    }

    public virtual int NetAccept(VmNetworkState state, int listenerHandle)
    {
        if (!state.NetListeners.TryGetValue(listenerHandle, out var listener))
        {
            return -1;
        }

        var client = listener.AcceptTcpClient();
        var connHandle = state.NextNetHandle++;
        state.NetConnections[connHandle] = client;
        if (state.NetTlsCertificates.TryGetValue(listenerHandle, out var cert))
        {
            var tlsStream = new SslStream(client.GetStream(), leaveInnerStreamOpen: false);
            try
            {
                tlsStream.AuthenticateAsServer(
                    cert,
                    clientCertificateRequired: false,
                    enabledSslProtocols: SslProtocols.Tls12 | SslProtocols.Tls13,
                    checkCertificateRevocation: false);
            }
            catch
            {
                tlsStream.Dispose();
                try { client.Close(); } catch { }
                state.NetConnections.Remove(connHandle);
                return -1;
            }

            state.NetTlsStreams[connHandle] = tlsStream;
        }

        return connHandle;
    }

    public virtual int NetTcpListen(VmNetworkState state, string host, int port)
    {
        var listener = new TcpListener(ResolveListenAddress(host), port);
        listener.Start();
        var handle = state.NextNetHandle++;
        state.NetListeners[handle] = listener;
        return handle;
    }

    public virtual int NetTcpListenTls(VmNetworkState state, string host, int port, string certPath, string keyPath)
    {
        X509Certificate2 certificate;
        try
        {
            certificate = X509Certificate2.CreateFromPemFile(certPath, keyPath);
        }
        catch
        {
            return -1;
        }

        var listener = new TcpListener(ResolveListenAddress(host), port);
        listener.Start();
        var handle = state.NextNetHandle++;
        state.NetListeners[handle] = listener;
        state.NetTlsCertificates[handle] = certificate;
        return handle;
    }

    public virtual int NetTcpAccept(VmNetworkState state, int listenerHandle)
    {
        return NetAccept(state, listenerHandle);
    }

    public virtual string NetTcpRead(VmNetworkState state, int connectionHandle, int maxBytes)
    {
        if (maxBytes <= 0 ||
            !state.NetConnections.TryGetValue(connectionHandle, out var client))
        {
            return string.Empty;
        }

        var stream = GetConnectionStream(state, client, connectionHandle);
        var buffer = new byte[maxBytes];
        var read = stream.Read(buffer, 0, buffer.Length);
        if (read <= 0)
        {
            return string.Empty;
        }

        return Encoding.UTF8.GetString(buffer, 0, read);
    }

    public virtual int NetTcpWrite(VmNetworkState state, int connectionHandle, string data)
    {
        if (!state.NetConnections.TryGetValue(connectionHandle, out var client))
        {
            return -1;
        }

        var stream = GetConnectionStream(state, client, connectionHandle);
        var payload = Encoding.UTF8.GetBytes(data);
        stream.Write(payload, 0, payload.Length);
        stream.Flush();
        return payload.Length;
    }

    public virtual int NetUdpBind(VmNetworkState state, string host, int port)
    {
        var endpoint = new IPEndPoint(ResolveListenAddress(host), port);
        var socket = new UdpClient(endpoint);
        var handle = state.NextNetHandle++;
        state.NetUdpSockets[handle] = socket;
        return handle;
    }

    public virtual VmUdpPacket NetUdpRecv(VmNetworkState state, int handle, int maxBytes)
    {
        if (maxBytes <= 0 || !state.NetUdpSockets.TryGetValue(handle, out var socket))
        {
            return new VmUdpPacket(string.Empty, 0, string.Empty);
        }

        var remote = new IPEndPoint(IPAddress.Any, 0);
        var payload = socket.Receive(ref remote);
        if (payload.Length > maxBytes)
        {
            Array.Resize(ref payload, maxBytes);
        }

        return new VmUdpPacket(remote.Address.ToString(), remote.Port, Encoding.UTF8.GetString(payload));
    }

    public virtual int NetUdpSend(VmNetworkState state, int handle, string host, int port, string data)
    {
        if (!state.NetUdpSockets.TryGetValue(handle, out var socket))
        {
            return -1;
        }

        var payload = Encoding.UTF8.GetBytes(data);
        var sent = socket.Send(payload, payload.Length, host, port);
        return sent;
    }

    public virtual int UiCreateWindow(string title, int width, int height)
    {
        if (string.IsNullOrWhiteSpace(title) || width <= 0 || height <= 0)
        {
            return -1;
        }

        var handle = _nextUiHandle++;
        if (_linuxUi is not null && _linuxUi.TryCreateWindow(handle, title, width, height))
        {
            _openWindows.Add(handle);
            ResetTransformStack(handle);
            return handle;
        }

        if (_windowsUi is not null && _windowsUi.TryCreateWindow(handle, title, width, height))
        {
            _openWindows.Add(handle);
            ResetTransformStack(handle);
            return handle;
        }

        if (_macUi is not null && _macUi.TryCreateWindow(handle, title, width, height))
        {
            _openWindows.Add(handle);
            ResetTransformStack(handle);
            return handle;
        }

        return -1;
    }

    public virtual void UiBeginFrame(int windowHandle)
    {
        if (_openWindows.Contains(windowHandle))
        {
            ResetTransformStack(windowHandle);
        }

        if (_linuxUi is not null && _linuxUi.TryBeginFrame(windowHandle))
        {
            return;
        }

        if (_windowsUi is not null && _windowsUi.TryBeginFrame(windowHandle))
        {
            return;
        }

        if (_macUi is not null && _macUi.TryBeginFrame(windowHandle))
        {
            return;
        }
    }

    public virtual void UiDrawRect(int windowHandle, int x, int y, int width, int height, string color)
    {
        if (width <= 0 || height <= 0)
        {
            return;
        }

        if (!IsAxisAlignedTransform(windowHandle))
        {
            for (var i = 0; i < height; i++)
            {
                UiDrawLine(windowHandle, x, y + i, x + width - 1, y + i, color, 1);
            }

            return;
        }

        var topLeft = ApplyTransform(windowHandle, x, y);
        var bottomRight = ApplyTransform(windowHandle, x + width, y + height);
        var drawX = Math.Min(topLeft.X, bottomRight.X);
        var drawY = Math.Min(topLeft.Y, bottomRight.Y);
        var drawWidth = Math.Abs(bottomRight.X - topLeft.X);
        var drawHeight = Math.Abs(bottomRight.Y - topLeft.Y);
        if (_linuxUi is not null && _linuxUi.TryDrawRect(windowHandle, drawX, drawY, drawWidth, drawHeight, color))
        {
            return;
        }

        if (_windowsUi is not null && _windowsUi.TryDrawRect(windowHandle, drawX, drawY, drawWidth, drawHeight, color))
        {
            return;
        }

        if (_macUi is not null && _macUi.TryDrawRect(windowHandle, drawX, drawY, drawWidth, drawHeight, color))
        {
            return;
        }
    }

    public virtual void UiDrawText(int windowHandle, int x, int y, string text, string color, int size)
    {
        var position = ApplyTransform(windowHandle, x, y);
        if (_linuxUi is not null && _linuxUi.TryDrawText(windowHandle, position.X, position.Y, text, color, size))
        {
            return;
        }

        if (_windowsUi is not null && _windowsUi.TryDrawText(windowHandle, position.X, position.Y, text, color, size))
        {
            return;
        }

        if (_macUi is not null && _macUi.TryDrawText(windowHandle, position.X, position.Y, text, color, size))
        {
            return;
        }
    }

    public virtual void UiDrawLine(int windowHandle, int x1, int y1, int x2, int y2, string color, int strokeWidth)
    {
        var start = ApplyTransform(windowHandle, x1, y1);
        var end = ApplyTransform(windowHandle, x2, y2);
        if (_linuxUi is not null && _linuxUi.TryDrawLine(windowHandle, start.X, start.Y, end.X, end.Y, color, strokeWidth))
        {
            return;
        }

        if (_windowsUi is not null && _windowsUi.TryDrawLine(windowHandle, start.X, start.Y, end.X, end.Y, color, strokeWidth))
        {
            return;
        }

        if (_macUi is not null && _macUi.TryDrawLine(windowHandle, start.X, start.Y, end.X, end.Y, color, strokeWidth))
        {
            return;
        }
    }

    public virtual void UiDrawEllipse(int windowHandle, int x, int y, int width, int height, string color)
    {
        if (width <= 0 || height <= 0)
        {
            return;
        }

        if (!IsAxisAlignedTransform(windowHandle))
        {
            var a = width / 2.0;
            var b = height / 2.0;
            var cx = x + a;
            var cy = y + b;
            for (var iy = 0; iy < height; iy++)
            {
                var yy = y + iy;
                var dy = yy - cy;
                var ratio = 1.0 - (dy * dy) / (b * b);
                if (ratio < 0.0)
                {
                    continue;
                }

                var dx = a * Math.Sqrt(ratio);
                var left = (int)Math.Round(cx - dx, MidpointRounding.AwayFromZero);
                var right = (int)Math.Round(cx + dx, MidpointRounding.AwayFromZero);
                UiDrawLine(windowHandle, left, yy, right, yy, color, 1);
            }

            return;
        }

        var topLeft = ApplyTransform(windowHandle, x, y);
        var bottomRight = ApplyTransform(windowHandle, x + width, y + height);
        var drawX = Math.Min(topLeft.X, bottomRight.X);
        var drawY = Math.Min(topLeft.Y, bottomRight.Y);
        var drawWidth = Math.Abs(bottomRight.X - topLeft.X);
        var drawHeight = Math.Abs(bottomRight.Y - topLeft.Y);
        if (_linuxUi is not null && _linuxUi.TryDrawEllipse(windowHandle, drawX, drawY, drawWidth, drawHeight, color))
        {
            return;
        }

        if (_windowsUi is not null && _windowsUi.TryDrawEllipse(windowHandle, drawX, drawY, drawWidth, drawHeight, color))
        {
            return;
        }

        if (_macUi is not null && _macUi.TryDrawEllipse(windowHandle, drawX, drawY, drawWidth, drawHeight, color))
        {
            return;
        }
    }

    public virtual void UiDrawPath(int windowHandle, string path, string color, int strokeWidth)
    {
        var points = UiDrawCommand.ParsePathPoints(path);
        if (points.Count < 2)
        {
            return;
        }

        for (var i = 1; i < points.Count; i++)
        {
            UiDrawLine(windowHandle, points[i - 1].X, points[i - 1].Y, points[i].X, points[i].Y, color, strokeWidth);
        }
    }

    public virtual void UiDrawPolyline(int windowHandle, string points, string color, int strokeWidth)
    {
        UiDrawPath(windowHandle, points, color, strokeWidth);
    }

    public virtual void UiDrawPolygon(int windowHandle, string points, string color, int strokeWidth)
    {
        var parsed = UiDrawCommand.ParsePathPoints(points);
        if (parsed.Count < 3)
        {
            return;
        }

        for (var i = 1; i < parsed.Count; i++)
        {
            UiDrawLine(windowHandle, parsed[i - 1].X, parsed[i - 1].Y, parsed[i].X, parsed[i].Y, color, strokeWidth);
        }

        UiDrawLine(
            windowHandle,
            parsed[^1].X,
            parsed[^1].Y,
            parsed[0].X,
            parsed[0].Y,
            color,
            strokeWidth);
    }

    public virtual void UiDrawTextPath(int windowHandle, string path, string text, string color, int size)
    {
        var points = UiDrawCommand.ParsePathPoints(path);
        if (points.Count == 0)
        {
            return;
        }

        var content = text ?? string.Empty;
        if (content.Length == 0)
        {
            return;
        }

        var glyphPoses = BuildTextPathPoses(points, content.Length);
        for (var i = 0; i < content.Length && i < glyphPoses.Count; i++)
        {
            UiGroupPush(windowHandle);
            UiTranslate(windowHandle, glyphPoses[i].X, glyphPoses[i].Y);
            if (glyphPoses[i].AngleDegrees != 0)
            {
                UiRotate(windowHandle, glyphPoses[i].AngleDegrees);
            }

            UiTranslate(windowHandle, -glyphPoses[i].X, -glyphPoses[i].Y);
            UiDrawText(
                windowHandle,
                glyphPoses[i].X,
                glyphPoses[i].Y,
                content[i].ToString(),
                color,
                size);
            UiGroupPop(windowHandle);
        }
    }

    public virtual void UiDrawRectPaint(int windowHandle, int x, int y, int width, int height, string fill, string stroke, int strokeWidth, int opacity)
    {
        if (width <= 0 || height <= 0)
        {
            return;
        }

        var normalizedStrokeWidth = Math.Max(0, strokeWidth);

        if (TryParseLinearGradient(fill, opacity, out var fillGradient))
        {
            if (fillGradient!.Vertical)
            {
                for (var i = 0; i < height; i++)
                {
                    var color = InterpolateHexColor(fillGradient.StartColor, fillGradient.EndColor, i, Math.Max(1, height - 1));
                    UiDrawLine(windowHandle, x, y + i, x + width - 1, y + i, color, 1);
                }
            }
            else
            {
                for (var i = 0; i < width; i++)
                {
                    var color = InterpolateHexColor(fillGradient.StartColor, fillGradient.EndColor, i, Math.Max(1, width - 1));
                    UiDrawLine(windowHandle, x + i, y, x + i, y + height - 1, color, 1);
                }
            }
        }
        else
        {
            var fillColor = ApplyOpacity(fill, opacity);
            if (!string.IsNullOrWhiteSpace(fillColor))
            {
                UiDrawRect(windowHandle, x, y, width, height, fillColor);
            }
        }

        if (!string.IsNullOrWhiteSpace(stroke) && normalizedStrokeWidth > 0)
        {
            DrawGradientLine(windowHandle, x, y, x + width - 1, y, stroke, normalizedStrokeWidth, opacity);
            DrawGradientLine(windowHandle, x, y + Math.Max(0, height - 1), x + width - 1, y + Math.Max(0, height - 1), stroke, normalizedStrokeWidth, opacity);
            DrawGradientLine(windowHandle, x, y, x, y + height - 1, stroke, normalizedStrokeWidth, opacity);
            DrawGradientLine(windowHandle, x + Math.Max(0, width - 1), y, x + Math.Max(0, width - 1), y + height - 1, stroke, normalizedStrokeWidth, opacity);
        }
    }

    public virtual void UiDrawEllipsePaint(int windowHandle, int x, int y, int width, int height, string fill, string stroke, int strokeWidth, int opacity)
    {
        if (width <= 0 || height <= 0)
        {
            return;
        }

        var normalizedStrokeWidth = Math.Max(0, strokeWidth);

        if (TryParseLinearGradient(fill, opacity, out var fillGradient))
        {
            var a = width / 2.0;
            var b = height / 2.0;
            var cx = x + a;
            var cy = y + b;
            if (fillGradient!.Vertical)
            {
                for (var iy = 0; iy < height; iy++)
                {
                    var yy = y + iy;
                    var dy = yy - cy;
                    var ratio = 1.0 - (dy * dy) / (b * b);
                    if (ratio < 0.0)
                    {
                        continue;
                    }

                    var dx = a * Math.Sqrt(ratio);
                    var left = (int)Math.Round(cx - dx, MidpointRounding.AwayFromZero);
                    var right = (int)Math.Round(cx + dx, MidpointRounding.AwayFromZero);
                    var color = InterpolateHexColor(fillGradient.StartColor, fillGradient.EndColor, iy, Math.Max(1, height - 1));
                    UiDrawLine(windowHandle, left, yy, right, yy, color, 1);
                }
            }
            else
            {
                for (var ix = 0; ix < width; ix++)
                {
                    var xx = x + ix;
                    var dx = xx - cx;
                    var ratio = 1.0 - (dx * dx) / (a * a);
                    if (ratio < 0.0)
                    {
                        continue;
                    }

                    var dy = b * Math.Sqrt(ratio);
                    var top = (int)Math.Round(cy - dy, MidpointRounding.AwayFromZero);
                    var bottom = (int)Math.Round(cy + dy, MidpointRounding.AwayFromZero);
                    var color = InterpolateHexColor(fillGradient.StartColor, fillGradient.EndColor, ix, Math.Max(1, width - 1));
                    UiDrawLine(windowHandle, xx, top, xx, bottom, color, 1);
                }
            }
        }
        else
        {
            var fillColor = ApplyOpacity(fill, opacity);
            if (!string.IsNullOrWhiteSpace(fillColor))
            {
                UiDrawEllipse(windowHandle, x, y, width, height, fillColor);
            }
        }

        if (!string.IsNullOrWhiteSpace(stroke) && normalizedStrokeWidth > 0)
        {
            var segments = 32;
            var a = width / 2.0;
            var b = height / 2.0;
            var cx = x + a;
            var cy = y + b;
            var prev = (X: x + width, Y: (int)Math.Round(cy, MidpointRounding.AwayFromZero));
            for (var i = 1; i <= segments; i++)
            {
                var theta = 2.0 * Math.PI * i / segments;
                var next = (
                    X: (int)Math.Round(cx + a * Math.Cos(theta), MidpointRounding.AwayFromZero),
                    Y: (int)Math.Round(cy + b * Math.Sin(theta), MidpointRounding.AwayFromZero));
                DrawGradientLine(windowHandle, prev.X, prev.Y, next.X, next.Y, stroke, normalizedStrokeWidth, opacity);
                prev = next;
            }
        }
    }

    public virtual void UiDrawPolylinePaint(int windowHandle, string points, string stroke, int strokeWidth, int opacity)
    {
        if (string.IsNullOrWhiteSpace(stroke))
        {
            return;
        }

        var parsed = UiDrawCommand.ParsePathPoints(points);
        if (parsed.Count < 2)
        {
            return;
        }

        for (var i = 1; i < parsed.Count; i++)
        {
            DrawGradientLine(windowHandle, parsed[i - 1].X, parsed[i - 1].Y, parsed[i].X, parsed[i].Y, stroke, Math.Max(1, strokeWidth), opacity);
        }
    }

    public virtual void UiDrawPolygonPaint(int windowHandle, string points, string fill, string stroke, int strokeWidth, int opacity)
    {
        var parsed = UiDrawCommand.ParsePathPoints(points);
        DrawPathPaintInternal(windowHandle, parsed, fill, stroke, strokeWidth, opacity, closed: true);
    }

    public virtual void UiDrawPathPaint(int windowHandle, string path, string fill, string stroke, int strokeWidth, int opacity, int closed)
    {
        var parsed = UiDrawCommand.ParsePathPoints(path);
        DrawPathPaintInternal(windowHandle, parsed, fill, stroke, strokeWidth, opacity, closed != 0);
    }

    public virtual void UiDrawTextPaint(int windowHandle, int x, int y, string text, string color, int size, int opacity)
    {
        if (TryParseLinearGradient(color, opacity, out var gradient))
        {
            var textValue = text ?? string.Empty;
            var divisor = Math.Max(1, textValue.Length - 1);
            for (var i = 0; i < textValue.Length; i++)
            {
                var ch = textValue[i].ToString();
                var colorAt = InterpolateHexColor(gradient!.StartColor, gradient.EndColor, i, divisor);
                UiDrawText(windowHandle, x + i * Math.Max(1, size / 2), y, ch, colorAt, size);
            }
            return;
        }

        var textColor = ApplyOpacity(color, opacity);
        if (string.IsNullOrWhiteSpace(textColor))
        {
            return;
        }

        UiDrawText(windowHandle, x, y, text, textColor, size);
    }

    public virtual void UiFilterBlur(int windowHandle, string path, string color, int strokeWidth, int radius, int opacity, int closed)
    {
        var points = UiDrawCommand.ParsePathPoints(path);
        if (points.Count < 2)
        {
            return;
        }

        var clampedRadius = Math.Clamp(radius, 1, 12);
        var baseStrokeWidth = Math.Max(1, strokeWidth);
        var isClosed = closed != 0;
        for (var dy = -clampedRadius; dy <= clampedRadius; dy++)
        {
            for (var dx = -clampedRadius; dx <= clampedRadius; dx++)
            {
                var distance = Math.Abs(dx) + Math.Abs(dy);
                if (distance > clampedRadius)
                {
                    continue;
                }

                var passOpacity = Math.Max(0, opacity - (distance * 100 / (clampedRadius + 1)));
                var passColor = ResolvePaintColorAt(color, passOpacity, distance, Math.Max(1, clampedRadius));
                if (string.IsNullOrWhiteSpace(passColor))
                {
                    continue;
                }

                DrawBlurPass(windowHandle, points, passColor, baseStrokeWidth, dx, dy, isClosed);
            }
        }
    }

    public virtual void UiGroupPush(int windowHandle)
    {
        var stack = EnsureTransformStack(windowHandle);
        stack.Push(stack.Peek());
    }

    public virtual void UiGroupPop(int windowHandle)
    {
        var stack = EnsureTransformStack(windowHandle);
        if (stack.Count > 1)
        {
            _ = stack.Pop();
        }
    }

    public virtual void UiTranslate(int windowHandle, int dx, int dy)
    {
        var operation = new UiTransform2D(1.0, 0.0, 0.0, 1.0, dx, dy);
        PrependTransform(windowHandle, operation);
    }

    public virtual void UiScale(int windowHandle, int sx, int sy)
    {
        var operation = new UiTransform2D(sx, 0.0, 0.0, sy, 0.0, 0.0);
        PrependTransform(windowHandle, operation);
    }

    public virtual void UiRotate(int windowHandle, int degrees)
    {
        var radians = degrees * (Math.PI / 180.0);
        var sin = Math.Sin(radians);
        var cos = Math.Cos(radians);
        var operation = new UiTransform2D(cos, -sin, sin, cos, 0.0, 0.0);
        PrependTransform(windowHandle, operation);
    }

    public virtual void UiEndFrame(int windowHandle)
    {
        _ = _openWindows.Contains(windowHandle);
    }

    private void DrawPathPaintInternal(
        int windowHandle,
        List<(int X, int Y)> points,
        string fill,
        string stroke,
        int strokeWidth,
        int opacity,
        bool closed)
    {
        if (points.Count < 2)
        {
            return;
        }

        var normalizedStrokeWidth = Math.Max(1, strokeWidth);

        if (closed && points.Count >= 3 && !string.IsNullOrWhiteSpace(fill))
        {
            FillPolygonByScanline(windowHandle, points, fill, opacity);
        }

        if (!string.IsNullOrWhiteSpace(stroke))
        {
            for (var i = 1; i < points.Count; i++)
            {
                DrawGradientLine(windowHandle, points[i - 1].X, points[i - 1].Y, points[i].X, points[i].Y, stroke, normalizedStrokeWidth, opacity);
            }

            if (closed)
            {
                DrawGradientLine(windowHandle, points[^1].X, points[^1].Y, points[0].X, points[0].Y, stroke, normalizedStrokeWidth, opacity);
            }
        }
    }

    private void FillPolygonByScanline(int windowHandle, List<(int X, int Y)> points, string fillPaint, int opacity)
    {
        var minY = points.Min(p => p.Y);
        var maxY = points.Max(p => p.Y);
        if (minY > maxY)
        {
            return;
        }

        for (var y = minY; y <= maxY; y++)
        {
            var intersections = new List<int>();
            for (var i = 0; i < points.Count; i++)
            {
                var a = points[i];
                var b = points[(i + 1) % points.Count];
                if (a.Y == b.Y)
                {
                    continue;
                }

                var low = a.Y < b.Y ? a : b;
                var high = a.Y < b.Y ? b : a;
                if (y < low.Y || y >= high.Y)
                {
                    continue;
                }

                var t = (double)(y - low.Y) / (high.Y - low.Y);
                var x = (int)Math.Round(low.X + t * (high.X - low.X), MidpointRounding.AwayFromZero);
                intersections.Add(x);
            }

            intersections.Sort();
            for (var i = 0; i + 1 < intersections.Count; i += 2)
            {
                var fillColor = ResolvePaintColorAt(fillPaint, opacity, y - minY, Math.Max(1, maxY - minY));
                if (!string.IsNullOrWhiteSpace(fillColor))
                {
                    UiDrawLine(windowHandle, intersections[i], y, intersections[i + 1], y, fillColor, 1);
                }
            }
        }
    }

    private void DrawGradientLine(int windowHandle, int x1, int y1, int x2, int y2, string paint, int strokeWidth, int opacity)
    {
        if (TryParseLinearGradient(paint, opacity, out var gradient))
        {
            var segments = 24;
            var px = x1;
            var py = y1;
            for (var i = 1; i <= segments; i++)
            {
                var t = i / (double)segments;
                var nx = (int)Math.Round(x1 + (x2 - x1) * t, MidpointRounding.AwayFromZero);
                var ny = (int)Math.Round(y1 + (y2 - y1) * t, MidpointRounding.AwayFromZero);
                var color = InterpolateHexColor(gradient!.StartColor, gradient.EndColor, i, segments);
                UiDrawLine(windowHandle, px, py, nx, ny, color, strokeWidth);
                px = nx;
                py = ny;
            }

            return;
        }

        var colorValue = ApplyOpacity(paint, opacity);
        if (!string.IsNullOrWhiteSpace(colorValue))
        {
            UiDrawLine(windowHandle, x1, y1, x2, y2, colorValue, strokeWidth);
        }
    }

    private void DrawBlurPass(
        int windowHandle,
        List<(int X, int Y)> points,
        string color,
        int strokeWidth,
        int offsetX,
        int offsetY,
        bool closed)
    {
        for (var i = 1; i < points.Count; i++)
        {
            UiDrawLine(
                windowHandle,
                points[i - 1].X + offsetX,
                points[i - 1].Y + offsetY,
                points[i].X + offsetX,
                points[i].Y + offsetY,
                color,
                strokeWidth);
        }

        if (closed)
        {
            UiDrawLine(
                windowHandle,
                points[^1].X + offsetX,
                points[^1].Y + offsetY,
                points[0].X + offsetX,
                points[0].Y + offsetY,
                color,
                strokeWidth);
        }
    }

    private static string ResolvePaintColorAt(string paint, int opacity, int position, int span)
    {
        if (TryParseLinearGradient(paint, opacity, out var gradient))
        {
            return InterpolateHexColor(gradient!.StartColor, gradient.EndColor, position, span);
        }

        return ApplyOpacity(paint, opacity);
    }

    private static string ApplyOpacity(string color, int opacity)
    {
        if (string.IsNullOrWhiteSpace(color))
        {
            return string.Empty;
        }

        var clamped = Math.Clamp(opacity, 0, 100);
        var baseColor = NormalizeColor(color);
        if (baseColor.Length != 7 || !baseColor.StartsWith("#", StringComparison.Ordinal))
        {
            return baseColor;
        }

        var r = ParseColorHexByte(baseColor, 1);
        var g = ParseColorHexByte(baseColor, 3);
        var b = ParseColorHexByte(baseColor, 5);
        var alpha = clamped / 100.0;
        var rr = (int)Math.Round(r * alpha, MidpointRounding.AwayFromZero);
        var gg = (int)Math.Round(g * alpha, MidpointRounding.AwayFromZero);
        var bb = (int)Math.Round(b * alpha, MidpointRounding.AwayFromZero);
        return $"#{rr:X2}{gg:X2}{bb:X2}";
    }

    private static string NormalizeColor(string color)
    {
        if (color.StartsWith("#", StringComparison.Ordinal) && color.Length == 7)
        {
            return color;
        }

        return color.ToLowerInvariant() switch
        {
            "black" => "#000000",
            "red" => "#FF0000",
            "green" => "#00FF00",
            "blue" => "#0000FF",
            "white" => "#FFFFFF",
            _ => color
        };
    }

    private static bool TryParseLinearGradient(string paint, int opacity, out UiLinearGradient? gradient)
    {
        gradient = null;
        if (string.IsNullOrWhiteSpace(paint))
        {
            return false;
        }

        if (!paint.StartsWith("linear(", StringComparison.OrdinalIgnoreCase) || !paint.EndsWith(")", StringComparison.Ordinal))
        {
            return false;
        }

        var content = paint.Substring(7, paint.Length - 8);
        var parts = content.Split(',', StringSplitOptions.TrimEntries);
        if (parts.Length != 3)
        {
            return false;
        }

        var vertical = string.Equals(parts[0], "v", StringComparison.OrdinalIgnoreCase) ||
                       string.Equals(parts[0], "vertical", StringComparison.OrdinalIgnoreCase);
        var horizontal = string.Equals(parts[0], "h", StringComparison.OrdinalIgnoreCase) ||
                         string.Equals(parts[0], "horizontal", StringComparison.OrdinalIgnoreCase);
        if (!vertical && !horizontal)
        {
            return false;
        }

        var start = ApplyOpacity(parts[1], opacity);
        var end = ApplyOpacity(parts[2], opacity);
        if (!IsHexColor(start) || !IsHexColor(end))
        {
            return false;
        }

        gradient = new UiLinearGradient(vertical, start, end);
        return true;
    }

    private static string InterpolateHexColor(string start, string end, int position, int span)
    {
        var clampedSpan = Math.Max(1, span);
        var t = Math.Clamp(position / (double)clampedSpan, 0.0, 1.0);
        var sr = ParseColorHexByte(start, 1);
        var sg = ParseColorHexByte(start, 3);
        var sb = ParseColorHexByte(start, 5);
        var er = ParseColorHexByte(end, 1);
        var eg = ParseColorHexByte(end, 3);
        var eb = ParseColorHexByte(end, 5);
        var rr = (int)Math.Round(sr + (er - sr) * t, MidpointRounding.AwayFromZero);
        var gg = (int)Math.Round(sg + (eg - sg) * t, MidpointRounding.AwayFromZero);
        var bb = (int)Math.Round(sb + (eb - sb) * t, MidpointRounding.AwayFromZero);
        return $"#{rr:X2}{gg:X2}{bb:X2}";
    }

    private static bool IsHexColor(string value)
    {
        return value.Length == 7 && value.StartsWith("#", StringComparison.Ordinal);
    }

    private static List<UiGlyphPose> BuildTextPathPoses(List<(int X, int Y)> points, int glyphCount)
    {
        var poses = new List<UiGlyphPose>();
        if (glyphCount <= 0 || points.Count == 0)
        {
            return poses;
        }

        if (points.Count == 1)
        {
            for (var i = 0; i < glyphCount; i++)
            {
                poses.Add(new UiGlyphPose(points[0].X, points[0].Y, 0));
            }
            return poses;
        }

        var segmentLengths = new List<double>(Math.Max(0, points.Count - 1));
        var totalLength = 0.0;
        for (var i = 1; i < points.Count; i++)
        {
            var dx = points[i].X - points[i - 1].X;
            var dy = points[i].Y - points[i - 1].Y;
            var length = Math.Sqrt(dx * dx + dy * dy);
            segmentLengths.Add(length);
            totalLength += length;
        }

        if (totalLength <= 0.0)
        {
            for (var i = 0; i < glyphCount; i++)
            {
                poses.Add(new UiGlyphPose(points[0].X, points[0].Y, 0));
            }
            return poses;
        }

        var divisor = Math.Max(1, glyphCount - 1);
        for (var glyph = 0; glyph < glyphCount; glyph++)
        {
            var target = totalLength * glyph / divisor;
            var traversed = 0.0;
            var sampled = points[^1];
            var sampledAngle = 0;
            for (var seg = 0; seg < segmentLengths.Count; seg++)
            {
                var segLen = segmentLengths[seg];
                if (segLen <= 0.0)
                {
                    continue;
                }

                if (target <= traversed + segLen || seg == segmentLengths.Count - 1)
                {
                    var local = (target - traversed) / segLen;
                    var x = (int)Math.Round(points[seg].X + (points[seg + 1].X - points[seg].X) * local, MidpointRounding.AwayFromZero);
                    var y = (int)Math.Round(points[seg].Y + (points[seg + 1].Y - points[seg].Y) * local, MidpointRounding.AwayFromZero);
                    sampledAngle = (int)Math.Round(
                        Math.Atan2(points[seg + 1].Y - points[seg].Y, points[seg + 1].X - points[seg].X) * 180.0 / Math.PI,
                        MidpointRounding.AwayFromZero);
                    sampled = (x, y);
                    break;
                }

                traversed += segLen;
            }

            poses.Add(new UiGlyphPose(sampled.X, sampled.Y, sampledAngle));
        }

        return poses;
    }

    private static int ParseColorHexByte(string value, int start)
    {
        return int.Parse(value.AsSpan(start, 2), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
    }

    private void ResetTransformStack(int windowHandle)
    {
        var stack = EnsureTransformStack(windowHandle);
        stack.Clear();
        stack.Push(UiTransform2D.Identity);
    }

    private Stack<UiTransform2D> EnsureTransformStack(int windowHandle)
    {
        if (!_uiTransformStacks.TryGetValue(windowHandle, out var stack))
        {
            stack = new Stack<UiTransform2D>();
            stack.Push(UiTransform2D.Identity);
            _uiTransformStacks[windowHandle] = stack;
        }

        if (stack.Count == 0)
        {
            stack.Push(UiTransform2D.Identity);
        }

        return stack;
    }

    private void PrependTransform(int windowHandle, UiTransform2D operation)
    {
        var stack = EnsureTransformStack(windowHandle);
        var current = stack.Pop();
        stack.Push(Compose(operation, current));
    }

    private (int X, int Y) ApplyTransform(int windowHandle, int x, int y)
    {
        var stack = EnsureTransformStack(windowHandle);
        var transform = stack.Peek();
        var transformedX = transform.M11 * x + transform.M12 * y + transform.Dx;
        var transformedY = transform.M21 * x + transform.M22 * y + transform.Dy;
        return (
            (int)Math.Round(transformedX, MidpointRounding.AwayFromZero),
            (int)Math.Round(transformedY, MidpointRounding.AwayFromZero));
    }

    private bool IsAxisAlignedTransform(int windowHandle)
    {
        const double epsilon = 0.0000001;
        var transform = EnsureTransformStack(windowHandle).Peek();
        return Math.Abs(transform.M12) <= epsilon && Math.Abs(transform.M21) <= epsilon;
    }

    private static UiTransform2D Compose(UiTransform2D left, UiTransform2D right)
    {
        return new UiTransform2D(
            left.M11 * right.M11 + left.M12 * right.M21,
            left.M11 * right.M12 + left.M12 * right.M22,
            left.M21 * right.M11 + left.M22 * right.M21,
            left.M21 * right.M12 + left.M22 * right.M22,
            left.M11 * right.Dx + left.M12 * right.Dy + left.Dx,
            left.M21 * right.Dx + left.M22 * right.Dy + left.Dy);
    }

    private sealed record UiLinearGradient(bool Vertical, string StartColor, string EndColor);
    private sealed record UiGlyphPose(int X, int Y, int AngleDegrees);
    private sealed record UiTransform2D(double M11, double M12, double M21, double M22, double Dx, double Dy)
    {
        public static readonly UiTransform2D Identity = new(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    }

    public virtual VmUiEvent UiPollEvent(int windowHandle)
    {
        if (_linuxUi is not null)
        {
            return _linuxUi.PollEvent(windowHandle);
        }

        if (_windowsUi is not null)
        {
            return _windowsUi.PollEvent(windowHandle);
        }

        if (_macUi is not null)
        {
            return _macUi.PollEvent(windowHandle);
        }

        return new VmUiEvent("closed", string.Empty, -1, -1, string.Empty, string.Empty, string.Empty, false);
    }

    public virtual VmUiWindowSize UiGetWindowSize(int windowHandle)
    {
        if (_linuxUi is not null && _linuxUi.TryGetWindowSize(windowHandle, out var linuxWidth, out var linuxHeight))
        {
            return new VmUiWindowSize(linuxWidth, linuxHeight);
        }

        if (_windowsUi is not null && _windowsUi.TryGetWindowSize(windowHandle, out var windowsWidth, out var windowsHeight))
        {
            return new VmUiWindowSize(windowsWidth, windowsHeight);
        }

        if (_macUi is not null && _macUi.TryGetWindowSize(windowHandle, out var macWidth, out var macHeight))
        {
            return new VmUiWindowSize(macWidth, macHeight);
        }

        return new VmUiWindowSize(-1, -1);
    }

    public virtual void UiPresent(int windowHandle)
    {
        if (_linuxUi is not null && _linuxUi.TryPresent(windowHandle))
        {
            return;
        }

        if (_windowsUi is not null && _windowsUi.TryPresent(windowHandle))
        {
            return;
        }

        if (_macUi is not null && _macUi.TryPresent(windowHandle))
        {
            return;
        }
    }

    public virtual void UiCloseWindow(int windowHandle)
    {
        if (_linuxUi is not null && _linuxUi.TryCloseWindow(windowHandle))
        {
            _openWindows.Remove(windowHandle);
            _uiTransformStacks.Remove(windowHandle);
            return;
        }

        if (_windowsUi is not null && _windowsUi.TryCloseWindow(windowHandle))
        {
            _openWindows.Remove(windowHandle);
            _uiTransformStacks.Remove(windowHandle);
            return;
        }

        if (_macUi is not null && _macUi.TryCloseWindow(windowHandle))
        {
            _openWindows.Remove(windowHandle);
            _uiTransformStacks.Remove(windowHandle);
            return;
        }
    }

    public virtual string NetReadHeaders(VmNetworkState state, int connectionHandle)
    {
        if (!state.NetConnections.TryGetValue(connectionHandle, out var client))
        {
            return string.Empty;
        }

        var stream = GetConnectionStream(state, client, connectionHandle);
        var bytes = new List<byte>(1024);
        var endSeen = 0;
        var pattern = new byte[] { 13, 10, 13, 10 };
        while (bytes.Count < 65536)
        {
            var next = stream.ReadByte();
            if (next < 0)
            {
                break;
            }

            var b = (byte)next;
            bytes.Add(b);
            if (b == pattern[endSeen])
            {
                endSeen++;
                if (endSeen == 4)
                {
                    break;
                }
            }
            else
            {
                endSeen = b == pattern[0] ? 1 : 0;
            }
        }

        var headerText = Encoding.ASCII.GetString(bytes.ToArray());
        var contentLength = ParseContentLength(headerText);
        if (contentLength > 0)
        {
            var bodyBuffer = new byte[contentLength];
            var readTotal = 0;
            while (readTotal < contentLength)
            {
                var read = stream.Read(bodyBuffer, readTotal, contentLength - readTotal);
                if (read <= 0)
                {
                    break;
                }
                readTotal += read;
            }

            if (readTotal > 0)
            {
                headerText += Encoding.UTF8.GetString(bodyBuffer, 0, readTotal);
            }
        }

        return headerText;
    }

    public virtual bool NetWrite(VmNetworkState state, int connectionHandle, string text)
    {
        if (!state.NetConnections.TryGetValue(connectionHandle, out var client))
        {
            return false;
        }

        var bytes = Encoding.UTF8.GetBytes(text);
        var stream = GetConnectionStream(state, client, connectionHandle);
        stream.Write(bytes, 0, bytes.Length);
        stream.Flush();
        return true;
    }

    public virtual void NetClose(VmNetworkState state, int handle)
    {
        if (state.NetConnections.TryGetValue(handle, out var conn))
        {
            if (state.NetTlsStreams.TryGetValue(handle, out var tlsStream))
            {
                try { tlsStream.Dispose(); } catch { }
                state.NetTlsStreams.Remove(handle);
            }

            try { conn.Close(); } catch { }
            state.NetConnections.Remove(handle);
            return;
        }

        if (state.NetListeners.TryGetValue(handle, out var listener))
        {
            try { listener.Stop(); } catch { }
            state.NetListeners.Remove(handle);
            state.NetTlsCertificates.Remove(handle);
            return;
        }

        if (state.NetUdpSockets.TryGetValue(handle, out var socket))
        {
            try { socket.Close(); } catch { }
            state.NetUdpSockets.Remove(handle);
        }
    }

    public virtual void StdoutWriteLine(string text) => Console.WriteLine(text);

    public virtual void ProcessExit(int code) => throw new AosProcessExitException(code);

    private static int ParseContentLength(string raw)
    {
        foreach (var line in raw.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None))
        {
            if (line.StartsWith("Content-Length:", StringComparison.OrdinalIgnoreCase))
            {
                var value = line["Content-Length:".Length..].Trim();
                if (int.TryParse(value, out var parsed) && parsed > 0)
                {
                    return parsed;
                }

                return 0;
            }
        }

        return 0;
    }

    private static Stream GetConnectionStream(VmNetworkState state, TcpClient client, int connectionHandle)
    {
        return state.NetTlsStreams.TryGetValue(connectionHandle, out var tlsStream)
            ? tlsStream
            : client.GetStream();
    }

    private static IPAddress ResolveListenAddress(string host)
    {
        if (string.IsNullOrWhiteSpace(host) || string.Equals(host, "localhost", StringComparison.OrdinalIgnoreCase))
        {
            return IPAddress.Loopback;
        }

        if (string.Equals(host, "0.0.0.0", StringComparison.Ordinal) || string.Equals(host, "*", StringComparison.Ordinal))
        {
            return IPAddress.Any;
        }

        if (IPAddress.TryParse(host, out var address))
        {
            return address;
        }

        return IPAddress.Loopback;
    }

}
