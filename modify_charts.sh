#! /usr/bin/env sh

set -e -x

charts_tar=/var/ftp/pub/SN-G/charts/charts.tar.old

charts_dir=/var/tmp/charts_dir

# Unpackage charts.tar
if [ ! -d $charts_dir ]; then
    mkdir -p $charts_dir
else
    /usr/bin/rm -fr $charts_dir/*
fi

tar -xf $charts_tar -C $charts_dir

for file in `ls $charts_dir/charts/*.tgz`
do
    tar -xzf $file -C $charts_dir/charts
done

/usr/bin/rm -fr $charts_dir/charts/*.tgz

sh /root/scripts/check.sh $charts_dir > check1.out

sh /root/scripts/change.sh $charts_dir

sh /root/scripts/check.sh $charts_dir > check2.out

for i in `ls $charts_dir/charts/*md5`
do
    fn=`basename $i | sed 's/.md5//'`
    package_name=`echo $fn | awk -F'-[0-9]|-v[0-9]' '{print $1}'`

    echo $package_name
    if [ ! -d $charts_dir/charts/$dirname ];
    then
        echo "ERROR: Package $package_name doesn't exist."
        continue
    fi

    cd $charts_dir/charts/

    tar -zcf $fn $package_name
    md5sum $fn > ${fn}".md5"
    /usr/bin/rm -fr $package_name
done


cd $charts_dir
tar -cf charts.tar charts
/usr/bin/mv -f charts.tar /var/ftp/pub/SN-G/charts

