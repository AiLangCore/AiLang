namespace AiVM.Core;

public interface ISyscallHost
{
    string[] ProcessArgv();
    int TimeNowUnixMs();

    void ConsolePrintLine(string text);
    void IoPrint(string text);
    void IoWrite(string text);
    string IoReadLine();
    string IoReadAllStdin();
    string IoReadFile(string path);
    bool IoFileExists(string path);
    bool IoPathExists(string path);
    void IoMakeDir(string path);
    void IoWriteFile(string path, string text);

    string FsReadFile(string path);
    bool FsFileExists(string path);
    int StrUtf8ByteCount(string text);
    string HttpGet(string url);
    string Platform();
    string Architecture();
    string OsVersion();
    string Runtime();

    int NetListen(VmNetworkState state, int port);
    int NetListenTls(VmNetworkState state, int port, string certPath, string keyPath);
    int NetAccept(VmNetworkState state, int listenerHandle);
    string NetReadHeaders(VmNetworkState state, int connectionHandle);
    bool NetWrite(VmNetworkState state, int connectionHandle, string text);
    int NetTcpListen(VmNetworkState state, string host, int port);
    int NetTcpAccept(VmNetworkState state, int listenerHandle);
    string NetTcpRead(VmNetworkState state, int connectionHandle, int maxBytes);
    int NetTcpWrite(VmNetworkState state, int connectionHandle, string data);
    void NetClose(VmNetworkState state, int handle);

    void StdoutWriteLine(string text);
    void ProcessExit(int code);
}
