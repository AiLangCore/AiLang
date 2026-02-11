namespace AiLang.Core;

public sealed class AosPatchResult
{
    public AosPatchResult(AosNode? root, List<AosDiagnostic> diagnostics)
    {
        Root = root;
        Diagnostics = diagnostics;
    }

    public AosNode? Root { get; }
    public List<AosDiagnostic> Diagnostics { get; }
}

public sealed class AosPatchApplier
{
    public AosPatchResult Apply(AosNode root, IEnumerable<AosNode> ops)
    {
        var diagnostics = new List<AosDiagnostic>();
        var currentRoot = root;
        foreach (var op in ops)
        {
            if (!op.Attrs.TryGetValue("kind", out var kindAttr) || kindAttr.Kind != AosAttrKind.Identifier)
            {
                diagnostics.Add(new AosDiagnostic("PAT001", "Patch op missing kind.", op.Id, op.Span));
                continue;
            }

            var kind = kindAttr.AsString();
            switch (kind)
            {
                case "replaceNode":
                    if (!op.Attrs.TryGetValue("id", out var idAttr) || idAttr.Kind != AosAttrKind.Identifier)
                    {
                        diagnostics.Add(new AosDiagnostic("PAT002", "replaceNode requires id.", op.Id, op.Span));
                        continue;
                    }
                    if (op.Children.Count != 1)
                    {
                        diagnostics.Add(new AosDiagnostic("PAT003", "replaceNode requires one child node.", op.Id, op.Span));
                        continue;
                    }
                    currentRoot = ReplaceNode(currentRoot, idAttr.AsString(), op.Children[0], diagnostics) ?? currentRoot;
                    break;
                case "deleteNode":
                    if (!op.Attrs.TryGetValue("id", out var delAttr) || delAttr.Kind != AosAttrKind.Identifier)
                    {
                        diagnostics.Add(new AosDiagnostic("PAT004", "deleteNode requires id.", op.Id, op.Span));
                        continue;
                    }
                    currentRoot = DeleteNode(currentRoot, delAttr.AsString(), diagnostics) ?? currentRoot;
                    break;
                case "insertChild":
                    ApplyInsert(currentRoot, op, diagnostics);
                    break;
                default:
                    diagnostics.Add(new AosDiagnostic("PAT999", $"Unknown patch op '{kind}'.", op.Id, op.Span));
                    break;
            }
        }

        return new AosPatchResult(currentRoot, diagnostics);
    }

    private AosNode? ReplaceNode(AosNode root, string id, AosNode replacement, List<AosDiagnostic> diagnostics)
    {
        if (root.Id == id)
        {
            return replacement;
        }

        var (parent, index) = FindParent(root, id);
        if (parent is null)
        {
            diagnostics.Add(new AosDiagnostic("PAT005", $"Node '{id}' not found.", id, root.Span));
            return null;
        }

        parent.Children[index] = replacement;
        return root;
    }

    private AosNode? DeleteNode(AosNode root, string id, List<AosDiagnostic> diagnostics)
    {
        if (root.Id == id)
        {
            diagnostics.Add(new AosDiagnostic("PAT006", "Cannot delete root node.", id, root.Span));
            return null;
        }

        var (parent, index) = FindParent(root, id);
        if (parent is null)
        {
            diagnostics.Add(new AosDiagnostic("PAT005", $"Node '{id}' not found.", id, root.Span));
            return null;
        }

        parent.Children.RemoveAt(index);
        return root;
    }

    private void ApplyInsert(AosNode root, AosNode op, List<AosDiagnostic> diagnostics)
    {
        if (!op.Attrs.TryGetValue("parentId", out var parentAttr) || parentAttr.Kind != AosAttrKind.Identifier)
        {
            diagnostics.Add(new AosDiagnostic("PAT007", "insertChild requires parentId.", op.Id, op.Span));
            return;
        }

        if (!op.Attrs.TryGetValue("slot", out var slotAttr) || slotAttr.Kind != AosAttrKind.Identifier)
        {
            diagnostics.Add(new AosDiagnostic("PAT008", "insertChild requires slot.", op.Id, op.Span));
            return;
        }

        if (!op.Attrs.TryGetValue("index", out var indexAttr) || indexAttr.Kind != AosAttrKind.Int)
        {
            diagnostics.Add(new AosDiagnostic("PAT009", "insertChild requires index.", op.Id, op.Span));
            return;
        }

        if (op.Children.Count != 1)
        {
            diagnostics.Add(new AosDiagnostic("PAT010", "insertChild requires one child node.", op.Id, op.Span));
            return;
        }

        var parent = FindNode(root, parentAttr.AsString());
        if (parent is null)
        {
            diagnostics.Add(new AosDiagnostic("PAT011", $"Parent '{parentAttr.AsString()}' not found.", op.Id, op.Span));
            return;
        }

        if (!SlotAllowed(parent, slotAttr.AsString()))
        {
            diagnostics.Add(new AosDiagnostic("PAT012", $"Slot '{slotAttr.AsString()}' not valid for {parent.Kind}.", op.Id, op.Span));
            return;
        }

        var insertIndex = indexAttr.AsInt();
        if (insertIndex < 0 || insertIndex > parent.Children.Count)
        {
            diagnostics.Add(new AosDiagnostic("PAT013", "Insert index out of range.", op.Id, op.Span));
            return;
        }

        parent.Children.Insert(insertIndex, op.Children[0]);
    }

    private static bool SlotAllowed(AosNode parent, string slot)
    {
        return parent.Kind switch
        {
            "Program" => slot == "declarations",
            "Block" => slot == "statements",
            "Call" => slot == "args",
            _ => false
        };
    }

    private static AosNode? FindNode(AosNode node, string id)
    {
        if (node.Id == id)
        {
            return node;
        }

        foreach (var child in node.Children)
        {
            var found = FindNode(child, id);
            if (found is not null)
            {
                return found;
            }
        }

        return null;
    }

    private static (AosNode? parent, int index) FindParent(AosNode node, string id)
    {
        for (var i = 0; i < node.Children.Count; i++)
        {
            if (node.Children[i].Id == id)
            {
                return (node, i);
            }
            var result = FindParent(node.Children[i], id);
            if (result.parent is not null)
            {
                return result;
            }
        }
        return (null, -1);
    }
}
