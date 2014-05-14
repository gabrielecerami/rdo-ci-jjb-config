if [ "x$1" == "x" ] ; then
    echo "Usage: $0 project-name"
    exit 1
fi

projectfile=lib/projects/$1.yaml

if [ -e $projectfile ]; then
    echo "definitions container $1 already exists"
    exit 1
fi

if [ $(basename $(pwd)) == "scripts" ]; then
    echo "this script must be executed from the jjb config root dir using scripts/$0 "
    exit 1
fi

projectdir=jobs/$1
sed -e "s/khaleesi-basic/khaleesi-$1/g" lib/projects/example.yaml > $projectfile
mkdir $projectdir


for file in lib/*.yaml
    do
        ln -s ../../$file $projectdir/
    done
ln -s ../../$projectfile $projectdir/projects.yaml
