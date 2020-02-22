using Unicode

mutable struct Classification
    type::Symbol
    name::Symbol
    bio::String
    children::Vector{Classification}
    parent::Classification

    function Classification(classif::Dict{String, Any})
        children = [Classification(d) for d in get(classif, "children", [])]
        type = Symbol(Unicode.normalize(classif["type"], casefold=true, stripmark=true))
        name = Symbol(Unicode.normalize(classif["name"], casefold=true, stripmark=true))
        classif = new(type, name, get(classif, "bio", ""), children)
        for child in children
            child.parent = classif
        end
        classif
    end
end

function Base.show(io::IO, clf::Classification)
    if length(clf.children) < 2
        childrentext = " with $(length(clf.children)) child"
    else
        childrentext = " with $(length(clf.children)) children"
    end
    biotext = ""
    if clf.bio != ""
        biotext = " ($(clf.bio))"
    end
    print("Classification(", clf.type, " ", clf.name, biotext, childrentext, ")")
end

function getfirstparent(name::Symbol, classification::Classification)
    if classification.name == name
        parent = classification
        while parent.parent.name != :god
            parent = parent.parent
        end
        return parent
    else
        for child in classification.children
            parent = getfirstparent(name, child)
            if !isnothing(parent)
                return parent
            end
        end
    end
end
