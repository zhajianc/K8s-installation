charts_dir=$1

find  $charts_dir/charts -type f -exec sed -n '/^[[:space:]]*requests[[:space:]]*:[[:space:]]*$/,/^[[:space:]]*$\|^[[:space:]]*limits[[:space:]]*:[[:space:]]*$/p' {} \;
find  $charts_dir/charts -type f -exec sed -n '/^[[:space:]]*\(repository\|image\|exporterImage\|agentImage\|queryImage\|collectorImage\|sparkDependenciesImage\|esIndexCleanerImage\|imageRegistry\)[[:space:]]*:/p' {} \;

find  $charts_dir/charts -type f -exec sed -n '/10\.5\|127\.0\.0\.1/p' {} \;
find  $charts_dir/charts -type f -exec sed -n "/^[[:space:]]*\(size\|storage\)[[:space:]]*:[[:space:]]*\([\"\']\{0,1\}\)[0-9\.]\{0,\}/p" {} \;

