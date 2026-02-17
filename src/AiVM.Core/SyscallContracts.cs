namespace AiVM.Core;

public enum VmValueKind
{
    Unknown = 0,
    String = 1,
    Int = 2,
    Bool = 3,
    Node = 4,
    Void = 5
}

public static class SyscallContracts
{
    public static bool IsSysTarget(string target) => target.StartsWith("sys.", StringComparison.Ordinal);

    public static bool TryValidate(
        string target,
        IReadOnlyList<VmValueKind> argKinds,
        Action<string, string> addDiagnostic,
        out VmValueKind returnKind)
    {
        returnKind = VmValueKind.Unknown;
        switch (target)
        {
            case "sys.net_listen":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL123", "sys.net_listen expects 1 argument.", "VAL124", "sys.net_listen arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.net_listen_tls":
                ValidateArityAndTypes(
                    argKinds,
                    3,
                    new[]
                    {
                        (VmValueKind.Int, "VAL141", "sys.net_listen_tls arg 1 must be int."),
                        (VmValueKind.String, "VAL142", "sys.net_listen_tls arg 2 must be string."),
                        (VmValueKind.String, "VAL143", "sys.net_listen_tls arg 3 must be string.")
                    },
                    "VAL140",
                    "sys.net_listen_tls expects 3 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.net_accept":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL125", "sys.net_accept expects 1 argument.", "VAL126", "sys.net_accept arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.net_readHeaders":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL127", "sys.net_readHeaders expects 1 argument.", "VAL128", "sys.net_readHeaders arg must be int.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.net_write":
                ValidateArityAndTypes(
                    argKinds,
                    2,
                    new[]
                    {
                        (VmValueKind.Int, "VAL130", "sys.net_write arg 1 must be int."),
                        (VmValueKind.String, "VAL131", "sys.net_write arg 2 must be string.")
                    },
                    "VAL129",
                    "sys.net_write expects 2 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.net_close":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL132", "sys.net_close expects 1 argument.", "VAL133", "sys.net_close arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.net_tcpListen":
                ValidateArityAndTypes(
                    argKinds,
                    2,
                    new[]
                    {
                        (VmValueKind.String, "VAL208", "sys.net_tcpListen arg 1 must be string."),
                        (VmValueKind.Int, "VAL209", "sys.net_tcpListen arg 2 must be int.")
                    },
                    "VAL210",
                    "sys.net_tcpListen expects 2 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.net_tcpListenTls":
                ValidateArityAndTypes(
                    argKinds,
                    4,
                    new[]
                    {
                        (VmValueKind.String, "VAL211", "sys.net_tcpListenTls arg 1 must be string."),
                        (VmValueKind.Int, "VAL212", "sys.net_tcpListenTls arg 2 must be int."),
                        (VmValueKind.String, "VAL213", "sys.net_tcpListenTls arg 3 must be string."),
                        (VmValueKind.String, "VAL214", "sys.net_tcpListenTls arg 4 must be string.")
                    },
                    "VAL215",
                    "sys.net_tcpListenTls expects 4 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.net_tcpAccept":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL216", "sys.net_tcpAccept expects 1 argument.", "VAL217", "sys.net_tcpAccept arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.net_tcpRead":
                ValidateArityAndTypes(
                    argKinds,
                    2,
                    new[]
                    {
                        (VmValueKind.Int, "VAL218", "sys.net_tcpRead arg 1 must be int."),
                        (VmValueKind.Int, "VAL219", "sys.net_tcpRead arg 2 must be int.")
                    },
                    "VAL220",
                    "sys.net_tcpRead expects 2 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.net_tcpWrite":
                ValidateArityAndTypes(
                    argKinds,
                    2,
                    new[]
                    {
                        (VmValueKind.Int, "VAL221", "sys.net_tcpWrite arg 1 must be int."),
                        (VmValueKind.String, "VAL222", "sys.net_tcpWrite arg 2 must be string.")
                    },
                    "VAL223",
                    "sys.net_tcpWrite expects 2 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.net_udpBind":
                ValidateArityAndTypes(
                    argKinds,
                    2,
                    new[]
                    {
                        (VmValueKind.String, "VAL237", "sys.net_udpBind arg 1 must be string."),
                        (VmValueKind.Int, "VAL238", "sys.net_udpBind arg 2 must be int.")
                    },
                    "VAL239",
                    "sys.net_udpBind expects 2 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.net_udpRecv":
                ValidateArityAndTypes(
                    argKinds,
                    2,
                    new[]
                    {
                        (VmValueKind.Int, "VAL240", "sys.net_udpRecv arg 1 must be int."),
                        (VmValueKind.Int, "VAL241", "sys.net_udpRecv arg 2 must be int.")
                    },
                    "VAL242",
                    "sys.net_udpRecv expects 2 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Node;
                return true;
            case "sys.net_udpSend":
                ValidateArityAndTypes(
                    argKinds,
                    4,
                    new[]
                    {
                        (VmValueKind.Int, "VAL243", "sys.net_udpSend arg 1 must be int."),
                        (VmValueKind.String, "VAL244", "sys.net_udpSend arg 2 must be string."),
                        (VmValueKind.Int, "VAL245", "sys.net_udpSend arg 3 must be int."),
                        (VmValueKind.String, "VAL246", "sys.net_udpSend arg 4 must be string.")
                    },
                    "VAL247",
                    "sys.net_udpSend expects 4 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.ui_createWindow":
                ValidateArityAndTypes(
                    argKinds,
                    3,
                    new[]
                    {
                        (VmValueKind.String, "VAL248", "sys.ui_createWindow arg 1 must be string."),
                        (VmValueKind.Int, "VAL249", "sys.ui_createWindow arg 2 must be int."),
                        (VmValueKind.Int, "VAL250", "sys.ui_createWindow arg 3 must be int.")
                    },
                    "VAL251",
                    "sys.ui_createWindow expects 3 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.ui_beginFrame":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL252", "sys.ui_beginFrame expects 1 argument.", "VAL253", "sys.ui_beginFrame arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawRect":
                ValidateArityAndTypes(
                    argKinds,
                    6,
                    new[]
                    {
                        (VmValueKind.Int, "VAL254", "sys.ui_drawRect arg 1 must be int."),
                        (VmValueKind.Int, "VAL255", "sys.ui_drawRect arg 2 must be int."),
                        (VmValueKind.Int, "VAL256", "sys.ui_drawRect arg 3 must be int."),
                        (VmValueKind.Int, "VAL257", "sys.ui_drawRect arg 4 must be int."),
                        (VmValueKind.Int, "VAL258", "sys.ui_drawRect arg 5 must be int."),
                        (VmValueKind.String, "VAL259", "sys.ui_drawRect arg 6 must be string.")
                    },
                    "VAL260",
                    "sys.ui_drawRect expects 6 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawText":
                ValidateArityAndTypes(
                    argKinds,
                    6,
                    new[]
                    {
                        (VmValueKind.Int, "VAL261", "sys.ui_drawText arg 1 must be int."),
                        (VmValueKind.Int, "VAL262", "sys.ui_drawText arg 2 must be int."),
                        (VmValueKind.Int, "VAL263", "sys.ui_drawText arg 3 must be int."),
                        (VmValueKind.String, "VAL264", "sys.ui_drawText arg 4 must be string."),
                        (VmValueKind.String, "VAL265", "sys.ui_drawText arg 5 must be string."),
                        (VmValueKind.Int, "VAL266", "sys.ui_drawText arg 6 must be int.")
                    },
                    "VAL267",
                    "sys.ui_drawText expects 6 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawLine":
                ValidateArityAndTypes(
                    argKinds,
                    7,
                    new[]
                    {
                        (VmValueKind.Int, "VAL276", "sys.ui_drawLine arg 1 must be int."),
                        (VmValueKind.Int, "VAL277", "sys.ui_drawLine arg 2 must be int."),
                        (VmValueKind.Int, "VAL278", "sys.ui_drawLine arg 3 must be int."),
                        (VmValueKind.Int, "VAL279", "sys.ui_drawLine arg 4 must be int."),
                        (VmValueKind.Int, "VAL280", "sys.ui_drawLine arg 5 must be int."),
                        (VmValueKind.String, "VAL281", "sys.ui_drawLine arg 6 must be string."),
                        (VmValueKind.Int, "VAL282", "sys.ui_drawLine arg 7 must be int.")
                    },
                    "VAL283",
                    "sys.ui_drawLine expects 7 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawEllipse":
                ValidateArityAndTypes(
                    argKinds,
                    6,
                    new[]
                    {
                        (VmValueKind.Int, "VAL284", "sys.ui_drawEllipse arg 1 must be int."),
                        (VmValueKind.Int, "VAL285", "sys.ui_drawEllipse arg 2 must be int."),
                        (VmValueKind.Int, "VAL286", "sys.ui_drawEllipse arg 3 must be int."),
                        (VmValueKind.Int, "VAL287", "sys.ui_drawEllipse arg 4 must be int."),
                        (VmValueKind.Int, "VAL288", "sys.ui_drawEllipse arg 5 must be int."),
                        (VmValueKind.String, "VAL289", "sys.ui_drawEllipse arg 6 must be string.")
                    },
                    "VAL290",
                    "sys.ui_drawEllipse expects 6 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawPath":
                ValidateArityAndTypes(
                    argKinds,
                    4,
                    new[]
                    {
                        (VmValueKind.Int, "VAL291", "sys.ui_drawPath arg 1 must be int."),
                        (VmValueKind.String, "VAL292", "sys.ui_drawPath arg 2 must be string."),
                        (VmValueKind.String, "VAL293", "sys.ui_drawPath arg 3 must be string."),
                        (VmValueKind.Int, "VAL294", "sys.ui_drawPath arg 4 must be int.")
                    },
                    "VAL295",
                    "sys.ui_drawPath expects 4 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawPolyline":
                ValidateArityAndTypes(
                    argKinds,
                    4,
                    new[]
                    {
                        (VmValueKind.Int, "VAL296", "sys.ui_drawPolyline arg 1 must be int."),
                        (VmValueKind.String, "VAL297", "sys.ui_drawPolyline arg 2 must be string."),
                        (VmValueKind.String, "VAL298", "sys.ui_drawPolyline arg 3 must be string."),
                        (VmValueKind.Int, "VAL299", "sys.ui_drawPolyline arg 4 must be int.")
                    },
                    "VAL300",
                    "sys.ui_drawPolyline expects 4 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawPolygon":
                ValidateArityAndTypes(
                    argKinds,
                    4,
                    new[]
                    {
                        (VmValueKind.Int, "VAL301", "sys.ui_drawPolygon arg 1 must be int."),
                        (VmValueKind.String, "VAL302", "sys.ui_drawPolygon arg 2 must be string."),
                        (VmValueKind.String, "VAL303", "sys.ui_drawPolygon arg 3 must be string."),
                        (VmValueKind.Int, "VAL304", "sys.ui_drawPolygon arg 4 must be int.")
                    },
                    "VAL305",
                    "sys.ui_drawPolygon expects 4 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawTextPath":
                ValidateArityAndTypes(
                    argKinds,
                    5,
                    new[]
                    {
                        (VmValueKind.Int, "VAL306", "sys.ui_drawTextPath arg 1 must be int."),
                        (VmValueKind.String, "VAL307", "sys.ui_drawTextPath arg 2 must be string."),
                        (VmValueKind.String, "VAL308", "sys.ui_drawTextPath arg 3 must be string."),
                        (VmValueKind.String, "VAL309", "sys.ui_drawTextPath arg 4 must be string."),
                        (VmValueKind.Int, "VAL310", "sys.ui_drawTextPath arg 5 must be int.")
                    },
                    "VAL311",
                    "sys.ui_drawTextPath expects 5 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawRectPaint":
                ValidateArityAndTypes(
                    argKinds,
                    9,
                    new[]
                    {
                        (VmValueKind.Int, "VAL312", "sys.ui_drawRectPaint arg 1 must be int."),
                        (VmValueKind.Int, "VAL313", "sys.ui_drawRectPaint arg 2 must be int."),
                        (VmValueKind.Int, "VAL314", "sys.ui_drawRectPaint arg 3 must be int."),
                        (VmValueKind.Int, "VAL315", "sys.ui_drawRectPaint arg 4 must be int."),
                        (VmValueKind.Int, "VAL316", "sys.ui_drawRectPaint arg 5 must be int."),
                        (VmValueKind.String, "VAL317", "sys.ui_drawRectPaint arg 6 must be string."),
                        (VmValueKind.String, "VAL318", "sys.ui_drawRectPaint arg 7 must be string."),
                        (VmValueKind.Int, "VAL319", "sys.ui_drawRectPaint arg 8 must be int."),
                        (VmValueKind.Int, "VAL320", "sys.ui_drawRectPaint arg 9 must be int.")
                    },
                    "VAL321",
                    "sys.ui_drawRectPaint expects 9 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawEllipsePaint":
                ValidateArityAndTypes(
                    argKinds,
                    9,
                    new[]
                    {
                        (VmValueKind.Int, "VAL322", "sys.ui_drawEllipsePaint arg 1 must be int."),
                        (VmValueKind.Int, "VAL323", "sys.ui_drawEllipsePaint arg 2 must be int."),
                        (VmValueKind.Int, "VAL324", "sys.ui_drawEllipsePaint arg 3 must be int."),
                        (VmValueKind.Int, "VAL325", "sys.ui_drawEllipsePaint arg 4 must be int."),
                        (VmValueKind.Int, "VAL326", "sys.ui_drawEllipsePaint arg 5 must be int."),
                        (VmValueKind.String, "VAL327", "sys.ui_drawEllipsePaint arg 6 must be string."),
                        (VmValueKind.String, "VAL328", "sys.ui_drawEllipsePaint arg 7 must be string."),
                        (VmValueKind.Int, "VAL329", "sys.ui_drawEllipsePaint arg 8 must be int."),
                        (VmValueKind.Int, "VAL330", "sys.ui_drawEllipsePaint arg 9 must be int.")
                    },
                    "VAL331",
                    "sys.ui_drawEllipsePaint expects 9 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawPolylinePaint":
                ValidateArityAndTypes(
                    argKinds,
                    5,
                    new[]
                    {
                        (VmValueKind.Int, "VAL332", "sys.ui_drawPolylinePaint arg 1 must be int."),
                        (VmValueKind.String, "VAL333", "sys.ui_drawPolylinePaint arg 2 must be string."),
                        (VmValueKind.String, "VAL334", "sys.ui_drawPolylinePaint arg 3 must be string."),
                        (VmValueKind.Int, "VAL335", "sys.ui_drawPolylinePaint arg 4 must be int."),
                        (VmValueKind.Int, "VAL336", "sys.ui_drawPolylinePaint arg 5 must be int.")
                    },
                    "VAL337",
                    "sys.ui_drawPolylinePaint expects 5 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawPolygonPaint":
                ValidateArityAndTypes(
                    argKinds,
                    6,
                    new[]
                    {
                        (VmValueKind.Int, "VAL338", "sys.ui_drawPolygonPaint arg 1 must be int."),
                        (VmValueKind.String, "VAL339", "sys.ui_drawPolygonPaint arg 2 must be string."),
                        (VmValueKind.String, "VAL340", "sys.ui_drawPolygonPaint arg 3 must be string."),
                        (VmValueKind.String, "VAL341", "sys.ui_drawPolygonPaint arg 4 must be string."),
                        (VmValueKind.Int, "VAL342", "sys.ui_drawPolygonPaint arg 5 must be int."),
                        (VmValueKind.Int, "VAL343", "sys.ui_drawPolygonPaint arg 6 must be int.")
                    },
                    "VAL344",
                    "sys.ui_drawPolygonPaint expects 6 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawPathPaint":
                ValidateArityAndTypes(
                    argKinds,
                    7,
                    new[]
                    {
                        (VmValueKind.Int, "VAL345", "sys.ui_drawPathPaint arg 1 must be int."),
                        (VmValueKind.String, "VAL346", "sys.ui_drawPathPaint arg 2 must be string."),
                        (VmValueKind.String, "VAL347", "sys.ui_drawPathPaint arg 3 must be string."),
                        (VmValueKind.String, "VAL348", "sys.ui_drawPathPaint arg 4 must be string."),
                        (VmValueKind.Int, "VAL349", "sys.ui_drawPathPaint arg 5 must be int."),
                        (VmValueKind.Int, "VAL350", "sys.ui_drawPathPaint arg 6 must be int."),
                        (VmValueKind.Int, "VAL351", "sys.ui_drawPathPaint arg 7 must be int.")
                    },
                    "VAL352",
                    "sys.ui_drawPathPaint expects 7 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_drawTextPaint":
                ValidateArityAndTypes(
                    argKinds,
                    7,
                    new[]
                    {
                        (VmValueKind.Int, "VAL353", "sys.ui_drawTextPaint arg 1 must be int."),
                        (VmValueKind.Int, "VAL354", "sys.ui_drawTextPaint arg 2 must be int."),
                        (VmValueKind.Int, "VAL355", "sys.ui_drawTextPaint arg 3 must be int."),
                        (VmValueKind.String, "VAL356", "sys.ui_drawTextPaint arg 4 must be string."),
                        (VmValueKind.String, "VAL357", "sys.ui_drawTextPaint arg 5 must be string."),
                        (VmValueKind.Int, "VAL358", "sys.ui_drawTextPaint arg 6 must be int."),
                        (VmValueKind.Int, "VAL359", "sys.ui_drawTextPaint arg 7 must be int.")
                    },
                    "VAL360",
                    "sys.ui_drawTextPaint expects 7 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_filterBlur":
                ValidateArityAndTypes(
                    argKinds,
                    7,
                    new[]
                    {
                        (VmValueKind.Int, "VAL361", "sys.ui_filterBlur arg 1 must be int."),
                        (VmValueKind.String, "VAL362", "sys.ui_filterBlur arg 2 must be string."),
                        (VmValueKind.String, "VAL363", "sys.ui_filterBlur arg 3 must be string."),
                        (VmValueKind.Int, "VAL364", "sys.ui_filterBlur arg 4 must be int."),
                        (VmValueKind.Int, "VAL365", "sys.ui_filterBlur arg 5 must be int."),
                        (VmValueKind.Int, "VAL366", "sys.ui_filterBlur arg 6 must be int."),
                        (VmValueKind.Int, "VAL367", "sys.ui_filterBlur arg 7 must be int.")
                    },
                    "VAL368",
                    "sys.ui_filterBlur expects 7 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_groupPush":
                ValidateArityAndTypes(
                    argKinds,
                    1,
                    new[]
                    {
                        (VmValueKind.Int, "VAL369", "sys.ui_groupPush arg 1 must be int.")
                    },
                    "VAL370",
                    "sys.ui_groupPush expects 1 argument.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_groupPop":
                ValidateArityAndTypes(
                    argKinds,
                    1,
                    new[]
                    {
                        (VmValueKind.Int, "VAL371", "sys.ui_groupPop arg 1 must be int.")
                    },
                    "VAL372",
                    "sys.ui_groupPop expects 1 argument.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_translate":
                ValidateArityAndTypes(
                    argKinds,
                    3,
                    new[]
                    {
                        (VmValueKind.Int, "VAL373", "sys.ui_translate arg 1 must be int."),
                        (VmValueKind.Int, "VAL374", "sys.ui_translate arg 2 must be int."),
                        (VmValueKind.Int, "VAL375", "sys.ui_translate arg 3 must be int.")
                    },
                    "VAL376",
                    "sys.ui_translate expects 3 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_scale":
                ValidateArityAndTypes(
                    argKinds,
                    3,
                    new[]
                    {
                        (VmValueKind.Int, "VAL377", "sys.ui_scale arg 1 must be int."),
                        (VmValueKind.Int, "VAL378", "sys.ui_scale arg 2 must be int."),
                        (VmValueKind.Int, "VAL379", "sys.ui_scale arg 3 must be int.")
                    },
                    "VAL380",
                    "sys.ui_scale expects 3 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_rotate":
                ValidateArityAndTypes(
                    argKinds,
                    2,
                    new[]
                    {
                        (VmValueKind.Int, "VAL381", "sys.ui_rotate arg 1 must be int."),
                        (VmValueKind.Int, "VAL382", "sys.ui_rotate arg 2 must be int.")
                    },
                    "VAL383",
                    "sys.ui_rotate expects 2 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_endFrame":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL268", "sys.ui_endFrame expects 1 argument.", "VAL269", "sys.ui_endFrame arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_pollEvent":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL270", "sys.ui_pollEvent expects 1 argument.", "VAL271", "sys.ui_pollEvent arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Node;
                return true;
            case "sys.ui_present":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL272", "sys.ui_present expects 1 argument.", "VAL273", "sys.ui_present arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_closeWindow":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL274", "sys.ui_closeWindow expects 1 argument.", "VAL275", "sys.ui_closeWindow arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.ui_getWindowSize":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL276", "sys.ui_getWindowSize expects 1 argument.", "VAL277", "sys.ui_getWindowSize arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Node;
                return true;
            case "sys.crypto_base64Encode":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL224", "sys.crypto_base64Encode expects 1 argument.", "VAL225", "sys.crypto_base64Encode arg must be string.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.crypto_base64Decode":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL226", "sys.crypto_base64Decode expects 1 argument.", "VAL227", "sys.crypto_base64Decode arg must be string.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.crypto_sha1":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL228", "sys.crypto_sha1 expects 1 argument.", "VAL229", "sys.crypto_sha1 arg must be string.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.crypto_sha256":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL230", "sys.crypto_sha256 expects 1 argument.", "VAL231", "sys.crypto_sha256 arg must be string.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.crypto_hmacSha256":
                ValidateArityAndTypes(
                    argKinds,
                    2,
                    new[]
                    {
                        (VmValueKind.String, "VAL232", "sys.crypto_hmacSha256 arg 1 must be string."),
                        (VmValueKind.String, "VAL233", "sys.crypto_hmacSha256 arg 2 must be string.")
                    },
                    "VAL234",
                    "sys.crypto_hmacSha256 expects 2 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.crypto_randomBytes":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL235", "sys.crypto_randomBytes expects 1 argument.", "VAL236", "sys.crypto_randomBytes arg must be int.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.console_write":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL183", "sys.console_write expects 1 argument.", "VAL184", "sys.console_write arg must be string.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.console_writeLine":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL185", "sys.console_writeLine expects 1 argument.", "VAL186", "sys.console_writeLine arg must be string.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.console_readLine":
                ValidateArity(argKinds, 0, "VAL187", "sys.console_readLine expects 0 arguments.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.console_readAllStdin":
                ValidateArity(argKinds, 0, "VAL188", "sys.console_readAllStdin expects 0 arguments.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.console_writeErrLine":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL189", "sys.console_writeErrLine expects 1 argument.", "VAL190", "sys.console_writeErrLine arg must be string.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.process_cwd":
                ValidateArity(argKinds, 0, "VAL193", "sys.process_cwd expects 0 arguments.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.process_envGet":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL191", "sys.process_envGet expects 1 argument.", "VAL192", "sys.process_envGet arg must be string.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.time_nowUnixMs":
                ValidateArity(argKinds, 0, "VAL182", "sys.time_nowUnixMs expects 0 arguments.", addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.time_monotonicMs":
                ValidateArity(argKinds, 0, "VAL201", "sys.time_monotonicMs expects 0 arguments.", addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.time_sleepMs":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL202", "sys.time_sleepMs expects 1 argument.", "VAL203", "sys.time_sleepMs arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.stdout_writeLine":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL134", "sys.stdout_writeLine expects 1 argument.", "VAL135", "sys.stdout_writeLine arg must be string.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.proc_exit":
                ValidateArityAndType(argKinds, 1, VmValueKind.Int, "VAL136", "sys.proc_exit expects 1 argument.", "VAL137", "sys.proc_exit arg must be int.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.process_argv":
                ValidateArity(argKinds, 0, "VAL170", "sys.process_argv expects 0 arguments.", addDiagnostic);
                returnKind = VmValueKind.Node;
                return true;
            case "sys.fs_readFile":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL138", "sys.fs_readFile expects 1 argument.", "VAL139", "sys.fs_readFile arg must be string.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.fs_fileExists":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL140", "sys.fs_fileExists expects 1 argument.", "VAL141", "sys.fs_fileExists arg must be string.", addDiagnostic);
                returnKind = VmValueKind.Bool;
                return true;
            case "sys.fs_readDir":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL204", "sys.fs_readDir expects 1 argument.", "VAL205", "sys.fs_readDir arg must be string.", addDiagnostic);
                returnKind = VmValueKind.Node;
                return true;
            case "sys.fs_stat":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL206", "sys.fs_stat expects 1 argument.", "VAL207", "sys.fs_stat arg must be string.", addDiagnostic);
                returnKind = VmValueKind.Node;
                return true;
            case "sys.fs_pathExists":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL197", "sys.fs_pathExists expects 1 argument.", "VAL198", "sys.fs_pathExists arg must be string.", addDiagnostic);
                returnKind = VmValueKind.Bool;
                return true;
            case "sys.fs_writeFile":
                ValidateArityAndTypes(
                    argKinds,
                    2,
                    new[]
                    {
                        (VmValueKind.String, "VAL195", "sys.fs_writeFile arg 1 must be string."),
                        (VmValueKind.String, "VAL196", "sys.fs_writeFile arg 2 must be string.")
                    },
                    "VAL194",
                    "sys.fs_writeFile expects 2 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.fs_makeDir":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL199", "sys.fs_makeDir expects 1 argument.", "VAL200", "sys.fs_makeDir arg must be string.", addDiagnostic);
                returnKind = VmValueKind.Void;
                return true;
            case "sys.str_utf8ByteCount":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL142", "sys.str_utf8ByteCount expects 1 argument.", "VAL143", "sys.str_utf8ByteCount arg must be string.", addDiagnostic);
                returnKind = VmValueKind.Int;
                return true;
            case "sys.str_substring":
                ValidateArityAndTypes(
                    argKinds,
                    3,
                    new[]
                    {
                        (VmValueKind.String, "VAL278", "sys.str_substring arg 1 must be string."),
                        (VmValueKind.Int, "VAL279", "sys.str_substring arg 2 must be int."),
                        (VmValueKind.Int, "VAL280", "sys.str_substring arg 3 must be int.")
                    },
                    "VAL281",
                    "sys.str_substring expects 3 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.str_remove":
                ValidateArityAndTypes(
                    argKinds,
                    3,
                    new[]
                    {
                        (VmValueKind.String, "VAL282", "sys.str_remove arg 1 must be string."),
                        (VmValueKind.Int, "VAL283", "sys.str_remove arg 2 must be int."),
                        (VmValueKind.Int, "VAL284", "sys.str_remove arg 3 must be int.")
                    },
                    "VAL285",
                    "sys.str_remove expects 3 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.http_get":
                ValidateArityAndType(argKinds, 1, VmValueKind.String, "VAL148", "sys.http_get expects 1 argument.", "VAL149", "sys.http_get arg must be string.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.platform":
                ValidateArity(argKinds, 0, "VAL150", "sys.platform expects 0 arguments.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.arch":
                ValidateArity(argKinds, 0, "VAL151", "sys.arch expects 0 arguments.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.os_version":
                ValidateArity(argKinds, 0, "VAL152", "sys.os_version expects 0 arguments.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.runtime":
                ValidateArity(argKinds, 0, "VAL153", "sys.runtime expects 0 arguments.", addDiagnostic);
                returnKind = VmValueKind.String;
                return true;
            case "sys.vm_run":
                ValidateArityAndTypes(
                    argKinds,
                    3,
                    new[]
                    {
                        (VmValueKind.Node, "VAL145", "sys.vm_run arg 1 must be node."),
                        (VmValueKind.String, "VAL146", "sys.vm_run arg 2 must be string."),
                        (VmValueKind.Node, "VAL147", "sys.vm_run arg 3 must be node.")
                    },
                    "VAL144",
                    "sys.vm_run expects 3 arguments.",
                    addDiagnostic);
                returnKind = VmValueKind.Unknown;
                return true;
            default:
                return false;
        }
    }

    private static bool IsCompatible(VmValueKind actual, VmValueKind expected)
        => actual == expected || actual == VmValueKind.Unknown;

    private static void ValidateArity(
        IReadOnlyList<VmValueKind> argKinds,
        int expectedArity,
        string arityCode,
        string arityMessage,
        Action<string, string> addDiagnostic)
    {
        if (argKinds.Count != expectedArity)
        {
            addDiagnostic(arityCode, arityMessage);
        }
    }

    private static void ValidateArityAndType(
        IReadOnlyList<VmValueKind> argKinds,
        int expectedArity,
        VmValueKind expectedType,
        string arityCode,
        string arityMessage,
        string typeCode,
        string typeMessage,
        Action<string, string> addDiagnostic)
    {
        if (argKinds.Count != expectedArity)
        {
            addDiagnostic(arityCode, arityMessage);
            return;
        }

        if (!IsCompatible(argKinds[0], expectedType))
        {
            addDiagnostic(typeCode, typeMessage);
        }
    }

    private static void ValidateArityAndTypes(
        IReadOnlyList<VmValueKind> argKinds,
        int expectedArity,
        (VmValueKind type, string code, string message)[] expectedTypes,
        string arityCode,
        string arityMessage,
        Action<string, string> addDiagnostic)
    {
        if (argKinds.Count != expectedArity)
        {
            addDiagnostic(arityCode, arityMessage);
            return;
        }

        for (var i = 0; i < expectedTypes.Length; i++)
        {
            if (!IsCompatible(argKinds[i], expectedTypes[i].type))
            {
                addDiagnostic(expectedTypes[i].code, expectedTypes[i].message);
            }
        }
    }
}
