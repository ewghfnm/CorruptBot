--[[
    UIBuilder.lua
    Helpers for creating Instances with properties + children.
]]

local UIBuilder = {}

function UIBuilder.New(className, props, children)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                inst[k] = v
            end
        end
    end
    if children then
        for _, c in ipairs(children) do c.Parent = inst end
    end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

function UIBuilder.Corner(radius)
    return UIBuilder.New("UICorner", {CornerRadius = UDim.new(0, radius or 8)})
end

function UIBuilder.Stroke(color, thickness)
    return UIBuilder.New("UIStroke", {Color = color or Color3.fromRGB(0,0,0), Thickness = thickness or 2})
end

function UIBuilder.Padding(p)
    return UIBuilder.New("UIPadding", {
        PaddingTop = UDim.new(0,p), PaddingBottom = UDim.new(0,p),
        PaddingLeft = UDim.new(0,p), PaddingRight = UDim.new(0,p),
    })
end

function UIBuilder.ListLayout(props)
    props = props or {}
    props.Padding = props.Padding or UDim.new(0, 4)
    props.SortOrder = props.SortOrder or Enum.SortOrder.LayoutOrder
    return UIBuilder.New("UIListLayout", props)
end

function UIBuilder.GridLayout(props)
    props = props or {}
    props.CellSize = props.CellSize or UDim2.fromOffset(80, 80)
    props.CellPadding = props.CellPadding or UDim2.fromOffset(6, 6)
    return UIBuilder.New("UIGridLayout", props)
end

return UIBuilder
