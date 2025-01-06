#!/bin/bash

# Check deployments , statefulsets , daemonsets that have images from non private repo

PRIVATE_REGISTRY="docker.test.local"

is_private_image() {
    local image=$1
    if [[ $image == *"$PRIVATE_REGISTRY"* ]]; then
        return 0
    else
        return 1
    fi
}

RESOURCES=$(kubectl get deployments,statefulsets,daemonsets --all-namespaces -o jsonpath='{range .items[*]}{.kind}{" "}{.metadata.namespace}{" "}{.metadata.name}{" "}{.spec.template.spec.containers[*].image}{"\n"}{end}')

while read -r resource; do
    kind=$(echo "$resource" | awk '{print $1}')
    namespace=$(echo "$resource" | awk '{print $2}')
    name=$(echo "$resource" | awk '{print $3}')
    images=$(echo "$resource" | awk '{for (i=4; i<=NF; i++) print $i}')

    for image in $images; do
        if ! is_private_image "$image"; then
            echo "Non-private image found:"
            echo "  Resource Type: $kind"
            echo "  Namespace:     $namespace"
            echo "  Resource Name: $name"
            echo "  Image:         $image"
            echo "----------------------------------------"
        fi
    done
done <<< "$RESOURCES"
