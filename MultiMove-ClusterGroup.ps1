$ClusterGroupsToMove = "Available Storage", "Cluster Group"

foreach ($Group in $ClusterGroupsToMove) {
    Move-ClusterGroup -Name $Group -Wait 0
}