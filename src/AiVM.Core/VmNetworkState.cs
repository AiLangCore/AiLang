namespace AiVM.Core;

public sealed class VmNetworkState
{
    public Dictionary<int, System.Net.Sockets.TcpListener> NetListeners { get; } = new();
    public Dictionary<int, System.Net.Sockets.TcpClient> NetConnections { get; } = new();
    public Dictionary<int, System.Net.Sockets.UdpClient> NetUdpSockets { get; } = new();
    public Dictionary<int, System.Security.Cryptography.X509Certificates.X509Certificate2> NetTlsCertificates { get; } = new();
    public Dictionary<int, System.Net.Security.SslStream> NetTlsStreams { get; } = new();
    public Dictionary<int, VmNetAsyncOperation> NetAsyncOperations { get; } = new();
    public object NetAsyncLock { get; } = new();
    public Dictionary<int, VmWorkerOperation> WorkerOperations { get; } = new();
    public object WorkerLock { get; } = new();
    public Dictionary<int, VmDebugReplayState> DebugReplays { get; } = new();
    public object DebugLock { get; } = new();
    public int NextNetHandle { get; set; } = 1;
    public int NextNetAsyncHandle { get; set; } = 1;
    public int NextWorkerHandle { get; set; } = 1;
    public int NextDebugReplayHandle { get; set; } = 1;
}

public sealed class VmNetAsyncOperation
{
    public required System.Threading.Tasks.Task Task { get; set; }
    public VmNetAsyncOperationKind Kind { get; set; } = VmNetAsyncOperationKind.Generic;
    public int Status { get; set; } = 0;
    public bool Finalized { get; set; }
    public int IntResult { get; set; }
    public int PendingConnectionHandle { get; set; } = -1;
    public System.Net.Sockets.TcpClient? PendingTcpClient { get; set; }
    public System.Net.Security.SslStream? PendingTlsStream { get; set; }
    public string StringResult { get; set; } = string.Empty;
    public string Error { get; set; } = string.Empty;
}

public enum VmNetAsyncOperationKind
{
    Generic = 0,
    TcpConnect = 1,
    TcpConnectTls = 2
}

public sealed class VmWorkerOperation
{
    public required System.Threading.Tasks.Task Task { get; set; }
    public int Status { get; set; } = 0;
    public string Result { get; set; } = string.Empty;
    public string Error { get; set; } = string.Empty;
}

public sealed class VmDebugReplayState
{
    public required string[] Lines { get; init; }
    public int Index { get; set; }
}
