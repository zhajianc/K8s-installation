charts_dir=$1

find $charts_dir/charts/cassandra/templates -name config.yml -exec sed -i 's/Xms31G/Xms5G/g' {} \;

#find  $charts_dir/charts -type f -exec sed -i "s/\(^\s*\)\(repository\|image\|exporterImage\|agentImage\|queryImage\|collectorImage\|sparkDependenciesImage\|esIndexCleanerImage\|imageRegistry\)\s*:\s*\([\"\']\{0,1\}\)[0-9:\.]\{1,\}\(\/\|\s*$\)/\1\2: \3127.0.0.1:5000\4/gI;" {} \;

find  $charts_dir/charts -type f -exec sed -i "/^\s*requests\s*:\s*$/,/^\s*$\|^\s*limits\s*:\s*$/{s/\(^\s*\)\(memory\)\s*:\s*\([\"\']\{0,1\}\)[0-9\.]\{1,\}[EePpTtGgMmKki]\{1,\}\([\"\']\{0,1\}\)\s*$/\1\2: 100M/gI; s/\(^\s*\)\(cpu\)\s*:\s*\([\"\']\{0,1\}\)[0-9\.]\{1,\}[Mmi]\{0,2\}\([\"\']\{0,1\}\)\s*$/\1\2: 0.1/gI}" {} \;

#find  $charts_dir/charts -type f -exec sed -i "s/\(^\s*\)\(size\|storage\)\s*:\s*\([\"\']\{0,1\}\)\([0-9\.]\{1,\}\)\([EePpTtGgMmKki]\{1,2\}\)\([\"\']\{0,1\}\)\s*$/\1\2: 2Gi/g" {} \;

