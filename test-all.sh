#!/bin/bash

# make sure this script can be executed from any dir
cd $(dirname $0)

GREEN='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Running go generate..."
go generate

echo "Running go fmt..."
go fmt ./...

echo "Running unit tests..."
go test ./... || exit

# Race Detection
echo "Running race detection..."
if  go run --race . 2>&1 >/dev/null | grep -q "Found" ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED race detection run 'go run --race .' to identify"
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED race detection${NC}"
fi

echo "Building application..."
go build -ldflags="-s -w" || exit

echo '```' > LANGUAGES.md
./scc --languages >> LANGUAGES.md
echo '```' >> LANGUAGES.md


echo "Running with @file flag parsing syntax"
# include \n, \r\n and no line terminators
echo -e "go.mod\ngo.sum\r\nLICENSE" > flags.txt
if ./scc @flags.txt ; then
    echo -e "${GREEN}PASSED @file flag syntax"
    # post processing
    rm flags.txt
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should handle @file flag parsing syntax"
    echo -e "=======================================================${NC}"
    # post processing
    rm flags.txt
    exit
fi


echo "Building HTML report..."

./scc --format html -a --by-file -i go -o SCC-OUTPUT-REPORT.html

echo "Running integration tests..."

if ./scc --not-a-real-option > /dev/null ; then
    echo -e "${RED}================================================="
    echo -e "FAILED Invalid option should produce error code "
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED invalid option test"
fi

## NB you need to have pyyaml installed via pip install pyyaml for this to work
#if ./scc "examples/language/" --format cloc-yaml -o .tmp_scc_yaml >/dev/null && python <<EOS
#import yaml,sys
#try:
#    with open('.tmp_scc_yaml','r') as f:
#        data = yaml.load(f.read())
#        if type(data) is dict and data.keys():
#            sys.exit(0)
#        else:
#            print('data was {}'.format(type(data)))
#except Exception as e:
#    pass
#sys.exit(1)
#EOS
#
#then
#	echo -e "${GREEN}PASSED cloc-yaml format test"
#else
#    echo -e "${RED}======================================================="
#    echo -e "${RED}FAILED Should accept --format cloc-yaml and should generate valid output"
#    echo -e "=======================================================${NC}"
#    rm -f .tmp_scc_yaml
#    exit
#fi
#
#if ./scc "examples/language/" --format cloc-yml -o .tmp_scc_yaml >/dev/null && python <<EOS
#import yaml,sys
#try:
#    with open('.tmp_scc_yaml','r') as f:
#        data = yaml.load(f.read())
#        if type(data) is dict and data.keys():
#            sys.exit(0)
#        else:
#            print('data was {}'.format(type(data)))
#except Exception as e:
#    pass
#sys.exit(1)
#EOS
#
#then
#	echo -e "${GREEN}PASSED cloc-yml format test"
#else
#    echo -e "${RED}======================================================="
#    echo -e "${RED}FAILED Should accept --format cloc-yml and should generate valid output"
#    echo -e "=======================================================${NC}"
#    rm -f .tmp_scc_yaml
#    exit
#fi

if ./scc NOTAREALDIRECTORYORFILE > /dev/null ; then
    echo -e "${RED}================================================="
    echo -e "FAILED Invalid file/directory should produce error code "
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED invalid file/directory test"
fi

if ./scc > /dev/null ; then
    echo -e "${GREEN}PASSED no directory specified test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should run correctly with no directory specified"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc processor > /dev/null ; then
    echo -e "${GREEN}PASSED directory specified test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should run correctly with directory specified"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --avg-wage 10000 --binary --by-file --no-cocomo --no-size --size-unit si --include-symlinks --debug --exclude-dir .git -f tabular -i go -c -d -M something -s name -w processor > /dev/null ; then
    echo -e "${GREEN}PASSED multiple options test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should run correctly with multiple options"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -i sh -M "vendor|examples|p.*" > /dev/null ; then
    echo -e "${GREEN}PASSED regular expression ignore test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should run with regular expression ignore"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc "examples/shared_extension/" | grep -q "Coq"; then
    echo -e "${GREEN}PASSED shared extension test 1"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should be able to work with shared extension 1"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc "examples/shared_extension/" | grep -q "Verilog"; then
    echo -e "${GREEN}PASSED shared extension test 2"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should be able to work with shared extension 2"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc "examples/shared_extension/" | grep -q "V "; then
    echo -e "${GREEN}PASSED shared extension test 3"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should be able to work with shared extension 3"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --ci | grep -q "\-\-\-\-"; then
    echo -e "${GREEN}PASSED ci param test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should be able to work with ci flag"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc "examples/denylist/" | grep -q "Java"; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Should hit default .git denylist "
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED denylist test"
fi

# Simple test to see if we get any concurrency issues
for i in {1..100}
do
    if ./scc > /dev/null ; then
        :
    else
        echo -e "${RED}======================================================="
        echo -e "FAILED Should not have concurrency issue"
        echo -e "=================================================${NC}"
        exit
    fi
done
echo -e "${GREEN}PASSED concurrency issue test"

if ./scc main.go > /dev/null ; then
    echo -e "${GREEN}PASSED file specified test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should run correctly with a file is specified"
    echo -e "=================================================${NC}"
    exit
fi

# Multiple directory or file arguments
if ./scc main.go README.md | grep -q "Go " ; then
    echo -e "${GREEN}PASSED multiple file argument test 1"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should work with multiple file arguments 1"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc main.go README.md | grep -q "Markdown " ; then
    echo -e "${GREEN}PASSED multiple file argument test 2"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should work with multiple file arguments 2"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc processor scripts > /dev/null ; then
    echo -e "${GREEN}PASSED multiple directory specified test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should run correctly with multiple directory specified"
    echo -e "=================================================${NC}"
    exit
fi

# Try out duplicates
for i in {1..100}
do
    if ./scc -d "examples/duplicates/" | grep -e "Java" | grep -q -e " 1 "; then
        :
    else
        echo -e "${RED}======================================================="
        echo -e "FAILED Duplicates should be consistent"
        echo -e "=======================================================${NC}"
        exit
    fi
done
echo -e "${GREEN}PASSED duplicates test"

# Ensure deterministic output
a=$(./scc .)
for i in {1..100}
do
    b=$(./scc .)
    if [ "$a" == "$b" ]; then
        :
    else
        echo -e "${RED}======================================================="
        echo -e "FAILED Runs should be deterministic"
        echo -e "=======================================================${NC}"
        exit
    fi
done
echo -e "${GREEN}PASSED deterministic test"

# Check for multiple regex via https://github.com/andyfitzgerald
a=$(./scc --not-match="(.*\.hex|.*\.d|.*\.o|.*\.csv|^(./)?[0-9]{8}_.*)" . | grep Estimated | md5sum)
b=$(./scc --not-match=".*\.hex" --not-match=".*\.d" --not-match=".*\.o" --not-match=".*\.csv" --not-match="^(./)?[0-9]{8}_.*" . | grep Estimated | md5sum)
if [ "$a" == "$b" ]; then
    echo -e "${GREEN}PASSED multiple regex test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED multiple regex test"
    echo -e "=================================================${NC}"
    exit
fi

# Regression issue https://github.com/boyter/scc/issues/82
a=$(./scc . | grep Total)
b=$(./scc ${PWD} | grep Total)
if [ "$a" == "$b" ]; then
    echo -e "${GREEN}PASSED git filter"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED git filter"
    echo -e "=================================================${NC}"
    exit
fi

# Turn off gitignore https://github.com/boyter/scc/issues/53
touch ignored.xml
a=$(./scc | grep Total)
b=$(./scc --no-gitignore | grep Total)
if [ "$a" == "$b" ]; then
    echo -e "${RED}================================================="
    echo -e "FAILED git ignore filter"
    echo -e "=================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED git ignore filter"
fi

# Regression issue https://github.com/boyter/scc/issues/115
if ./scc "examples/issue115/.test/file" 2>&1 >/dev/null | grep -q "Perl" ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED hidden directory issue"
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED hidden directory${NC}"
fi


# Regression issue https://github.com/boyter/scc/issues/260
if ./scc -d "examples/issue260/" 2>&1 >/dev/null | grep -q "invalid memory address" ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED duplicate empty crash"
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED duplicate empty crash${NC}"
fi

a=$(./scc | grep Total)
b=$(./scc --no-ignore | grep Total)
if [ "$a" == "$b" ]; then
    echo "$a"
    echo "$b"
    echo -e "${RED}======================================================="
    echo -e "FAILED ignore filter"
    echo -e "=================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED ignore filter"
fi

if ./scc "examples/ignore/" | grep -q "Java "; then
    echo -e "${RED}======================================================="
    echo -e "FAILED multiple gitignore"
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED multiple gitignore"
fi

touch ./examples/ignore/ignorefile.txt
a=$(./scc --by-file --no-scc-ignore | grep ignorefile)
b=$(./scc --by-file --no-ignore --no-scc-ignore | grep ignorefile)
if [ "$a" == "$b" ]; then
    echo "$a"
    echo "$b"
    echo -e "${RED}======================================================="
    echo -e "FAILED ignore recursive filter"
    echo -e "=================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED ignore recursive filter"
fi

touch ./examples/ignore/gitignorefile.txt
a=$(./scc --by-file --no-scc-ignore | grep gitignorefile)
b=$(./scc --by-file --no-gitignore --no-scc-ignore | grep gitignorefile)
if [ "$a" == "$b" ]; then
    echo "$a"
    echo "$b"
    echo -e "${RED}======================================================="
    echo -e "FAILED gitignore recursive filter"
    echo -e "=================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED gitignore recursive filter"
fi

if ./scc "examples/language/" --include-ext go | grep -q "Java "; then
    echo -e "${RED}======================================================="
    echo -e "FAILED include-ext option"
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED include-ext option"
fi

a=$(./scc -i js ./examples/minified/ --no-scc-ignore)
b=$(./scc -i js -z ./examples/minified/ --no-scc-ignore)
if [ "$a" == "$b" ]; then
    echo "$a"
    echo "$b"
    echo -e "${RED}======================================================="
    echo -e "FAILED Minified check"
    echo -e "=================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED minified check"
fi

a=$(./scc -i js -z ./examples/minified/ --no-scc-ignore)
b=$(./scc -i js -z --no-min-gen ./examples/minified/ --no-scc-ignore)
if [ "$a" == "$b" ]; then
    echo "$a"
    echo "$b"
    echo -e "${RED}======================================================="
    echo -e "FAILED Minified ignored check"
    echo -e "=================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED minified ignored check"
fi

a=$(./scc ./examples/symlink/ --no-scc-ignore)
b=$(./scc --include-symlinks ./examples/symlink/ --no-scc-ignore)
if [ "$a" == "$b" ]; then
    echo "$a"
    echo "$b"
    echo -e "${RED}======================================================="
    echo -e "FAILED symlink check"
    echo -e "=================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED minified ignored check"
fi

if ./scc ./examples/minified/ --no-min-gen --no-scc-ignore | grep -q "\$0"; then
    echo -e "${GREEN}PASSED removed min"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED removed min"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc ./examples/generated/ --no-min-gen --no-scc-ignore | grep -q "\$0"; then
    echo -e "${GREEN}PASSED removed gen"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED removed gen"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -z ./examples/generated/ --no-scc-ignore | grep -q "C Header (gen)"; then
    echo -e "${GREEN}PASSED flagged as gen"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED flagged as gen"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc ./examples/minified/ -i js -z --no-scc-ignore | grep -q "JavaScript (min)"; then
    echo -e "${GREEN}PASSED flagged as min"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED flagged as min"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc ./examples/issue120/ -i java | grep -q "Perl"; then
    echo -e "${RED}======================================================="
    echo -e "FAILED extension param should ignore #!"
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED extension param should ignore #!"
fi

if ./scc -z --min-gen-line-length 1 --no-min-gen . | grep -q "\$0"; then
    echo -e "${GREEN}PASSED min gen line length"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED min gen line length"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --no-large --large-byte-count 0 ./examples/language | grep -q "\$0"; then
    echo -e "${GREEN}PASSED no large byte test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED no large byte test"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --no-large --large-line-count 0 ./examples/language | grep -q "\$0"; then
    echo -e "${GREEN}PASSED no large line test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED no large line test"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --format html | grep -q "html"; then
    echo -e "${GREEN}PASSED html output test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should be able to output to html"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --format html-table | grep -q "table"; then
    echo -e "${GREEN}PASSED html-table output test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should be able to output to html-table"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --format sql | grep -q "create table metadata"; then
    echo -e "${GREEN}PASSED sql output test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should be able to output to sql"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --format sql-insert | grep -q "insert into t values"; then
    echo -e "${GREEN}PASSED sql-insert output test"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED Should be able to output to sql-insert"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc ./examples/countas/ --count-as jsp:html | grep -q "HTML"; then
    echo -e "${GREEN}PASSED counted JSP as HTML"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED counted JSP as HTML"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc ./examples/countas/ --count-as JsP:html | grep -q "HTML"; then
    echo -e "${GREEN}PASSED counted JSP as HTML case"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED counted JSP as HTML case"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc ./examples/countas/ --count-as jsp:j2 | grep -q "Jinja"; then
    echo -e "${GREEN}PASSED counted JSP as Jinja"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED counted JSP as Jinja"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc ./examples/countas/ --count-as jsp:html,new:java | grep -q "Java"; then
    echo -e "${GREEN}PASSED counted new as Java"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED counted new as Java"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc ./examples/countas/ --count-as jsp:html,new:"C Header" | grep -q "C Header"; then
    echo -e "${GREEN}PASSED counted new as C Header"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED counted new as C Header"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -i css ./examples/issue152/ | grep -q "CSS"; then
    echo -e "${GREEN}PASSED -i extension check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED -i extension check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --file-gc-count 10 ./examples/duplicates/ -v | grep -q "read file limit exceeded GC re-enabled"; then
    echo -e "${GREEN}PASSED gc file count"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED gc file count"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -f csv | grep -q "Bytes"; then
    echo -e "${GREEN}PASSED csv bytes check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED csv bytes check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -f csv-stream | grep -q "Bytes"; then
    echo -e "${GREEN}PASSED csv-stream bytes check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED csv-stream bytes check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -f html | grep -q "Bytes"; then
    echo -e "${GREEN}PASSED html bytes check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED html bytes check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -f json | grep -q "Bytes"; then
    echo -e "${GREEN}PASSED json bytes check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED json bytes check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -f json  -a | grep -q "ULOC"; then
    echo -e "${GREEN}PASSED json uloc check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED json uloc check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -f json2 | grep -q "Bytes"; then
    echo -e "${GREEN}PASSED json2 bytes check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED json bytes check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc | grep -q "megabytes"; then
    echo -e "${GREEN}PASSED bytes check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED bytes check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -f csv | grep -q "Language,Lines,Code,Comments,Blanks,Complexity,Bytes,Files,ULOC"; then
    echo -e "${GREEN}PASSED csv summary"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED csv summary"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc -f csv --by-file | grep -q "Language,Provider,Filename,Lines,Code,Comments,Blanks,Complexity,Bytes"; then
    echo -e "${GREEN}PASSED csv file"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED csv file"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --by-file --format-multi "tabular:stdout,html:stdout,csv:stdout" | grep -q "Language,Provider"; then
    echo -e "${GREEN}PASSED format multi check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED format multi check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --format-multi "tabular:stdout,html:stdout,csv:stdout,sql:stdout" | grep -q "meta charset"; then
    echo -e "${GREEN}PASSED format multi check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED format multi check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --format-multi "tabular:stdout,html:stdout,csv:stdout,sql:stdout" | grep -q "insert into t values"; then
    echo -e "${GREEN}PASSED format multi check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED format multi check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --remap-unknown "-*- C++ -*-":"C Header" ./examples/remap/unknown | grep -q "C Header"; then
    echo -e "${GREEN}PASSED remap unknown"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED remap unknown"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --remap-all "-*- C++ -*-":"C Header" ./examples/remap/java.java | grep -q "C Header"; then
    echo -e "${GREEN}PASSED remap all"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED remap all"
    echo -e "=======================================================${NC}"
    exit
fi

./scc --format-multi "tabular:output.tab,wide:output.wide,json:output.json,json2:output2.json,csv:output.csv,cloc-yaml:output.yaml,html:output.html,html-table:output.html2,sql:output.sql"

if test -f output.tab; then
    echo -e "${GREEN}PASSED output.tab check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED output.tab check"
    echo -e "=======================================================${NC}"
    exit
fi

if test -f output.wide; then
    echo -e "${GREEN}PASSED output.wide check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED output.wide check"
    echo -e "=======================================================${NC}"
    exit
fi

if test -f output.json; then
    echo -e "${GREEN}PASSED output.json check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED output.json check"
    echo -e "=======================================================${NC}"
    exit
fi

if test -f output2.json; then
    echo -e "${GREEN}PASSED output2.json check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED output2.json check"
    echo -e "=======================================================${NC}"
    exit
fi

if test -f output.yaml; then
    echo -e "${GREEN}PASSED output.yaml check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED output.yaml check"
    echo -e "=======================================================${NC}"
    exit
fi

if test -f output.html; then
    echo -e "${GREEN}PASSED output.html check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED output.html check"
    echo -e "=======================================================${NC}"
    exit
fi

if test -f output.html2; then
    echo -e "${GREEN}PASSED output.html2 check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED output.html2 check"
    echo -e "=======================================================${NC}"
    exit
fi

if test -f output.sql; then
    echo -e "${GREEN}PASSED output.sql check"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED output.sql check"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --cocomo-project-type organic | grep -q "organic"; then
    echo -e "${GREEN}PASSED cocomo organic"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED cocomo organic"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --cocomo-project-type doesnotexist | grep -q "organic"; then
    echo -e "${GREEN}PASSED cocomo fallback"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED cocomo fallback"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --cocomo-project-type semi-detached | grep -q "semi-detached"; then
    echo -e "${GREEN}PASSED cocomo semi-detached"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED cocomo semi-detached"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --cocomo-project-type embedded | grep -q "embedded"; then
    echo -e "${GREEN}PASSED cocomo embedded"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED cocomo embedded"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --cocomo-project-type custom,1,1,1,1 | grep -q "custom,1,1,1,1"; then
    echo -e "${GREEN}PASSED cocomo custom,1,1,1,1"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED cocomo custom,1,1,1,1"
    echo -e "=======================================================${NC}"
    exit
fi

if ./scc --cocomo-project-type custom,1,1,1 | grep -q "organic"; then
    echo -e "${GREEN}PASSED cocomo custom fallback"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED cocomo custom fallback"
    echo -e "=======================================================${NC}"
    exit
fi

a=$(./scc --exclude-dir examples/)
b=$(./scc --exclude-dir examples)
if [ "$a" != "$b" ]; then
    echo "$a"
    echo "$b"
    echo -e "${RED}======================================================="
    echo -e "FAILED examples exclude-dir check"
    echo -e "=================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED examples exclude-dir check"
fi

a=$(./scc --exclude-ext go)
b=$(./scc)
if [ "$a" == "$b" ]; then
    echo "$a"
    echo "$b"
    echo -e "${RED}======================================================="
    echo -e "FAILED exclude-ext check"
    echo -e "=================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED exclude-ext check"
fi

# Issue 457
if ./scc -M ".*" | grep -q "0.000 megabytes"; then
    echo -e "${GREEN}PASSED issue 457"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED issue 457"
    echo -e "=======================================================${NC}"
    exit
fi

# Line length support
if ./scc -m | grep -q "MaxLine / MeanLine"; then
    echo -e "${GREEN}PASSED character option"
else
    echo -e "${RED}======================================================="
    echo -e "FAILED character option"
    echo -e "=======================================================${NC}"
    exit
fi

# Try out specific languages
specificLanguages=(
    'ABNF '
    'Alchemist '
    'Alloy '
    'Arturo '
    'Astro '
    'AWK '
    'BASH '
    'Bean '
    'Bicep '
    'Bitbucket Pipeline '
    'Blueprint '
    'Boo '
    'Bosque '
    'C3 '
    'C Shell '
    'C# '
    'Cairo '
    'Cangjie '
    'Chapel '
    'Circom '
    'Clipper '
    'Clojure '
    'CMake '
    'Cuda '
    'DAML '
    'DM '
    'Docker ignore '
    'Dockerfile '
    'DOT '
    'Elixir Template'
    'Elm '
    'EmiT '
    'F# '
    'Factor '
    'Flow9 '
    'FSL '
    'Futhark '
    'FXML '
    'Gemfile '
    'Gleam '
    'Go '
    'Go+ '
    'Godot Scene '
    'GraphQL '
    'Gwion '
    'HAML '
    'Hare '
    'HCL '
    'ignore '
    'INI '
    'Java '
    'JavaScript '
    'JCL '
    'JSON5 '
    'JSONC '
    'jq '
    'Korn Shell '
    'Koto '
    'LALRPOP '
    'License '
    'LiveScript '
    'LLVM IR '
    'Lua '
    'Luau '
    'Luna '
    'Makefile '
    'Metal '
    'Monkey C '
    'Moonbit '
    'Nushell '
    'OpenQASM '
    'OpenTofu '
    'Perl '
    'Pkl '
    'PostScript '
    'Proto '
    'Python '
    'Q# '
    'R '
    'Racket '
    'Rakefile '
    'RAML '
    'Redscript '
    'Scallop '
    'Shell '
    'Sieve '
    'Slang '
    'Slint '
    'Smalltalk '
    'Snakemake '
    'Stan '
    'Systemd '
    'Tact '
    'Teal '
    'Tera '
    'Templ '
    'Terraform '
    'TTCN-3 '
    'TypeScript '
    'TypeSpec '
    'Typst '
    'Up '
    'Vala '
    'Web Services '
    'wenyan '
    'Wren '
    'XMake '
    'XML Schema '
    'YAML '
    'Yarn '
    'Zig '
    'ZoKrates '
    'Zsh '
)
SPECIFIC_LANG_TEST_RESULT=$(./scc "examples/language/" --no-scc-ignore)
for i in "${specificLanguages[@]}"
do
    if echo "$SPECIFIC_LANG_TEST_RESULT" | grep -q "$i"; then
        echo -e "${GREEN}PASSED $i Language Check"
    else
        echo -e "${RED}======================================================="
        echo -e "FAILED Should be able to find $i"
        echo -e "=======================================================${NC}"
        exit
    fi
done

# Issue339
for i in 'MATLAB ' 'Objective C '
do
    if ./scc "examples/issue339/" --no-scc-ignore | grep -q "$i "; then
        echo -e "${GREEN}PASSED $i Language Check"
    else
        echo -e "${RED}======================================================="
        echo -e "FAILED Should be able to find $i"
        echo -e "=======================================================${NC}"
        exit
    fi
done

# Issue345 (https://github.com/boyter/scc/issues/345)
a=$(./scc "examples/issue345/" -f csv --no-scc-ignore | sed -n '2 p')
b="C++,4,3,1,0,0,76,1,0"
if [ "$a" == "$b" ]; then
    echo -e "${GREEN}PASSED String Termination Check"
else
    echo -e "$a"
    echo -e "${RED}======================================================="
    echo -e "FAILED Should terminate the string properly"
    echo -e "=======================================================${NC}"
    exit
fi

# Regression issue https://github.com/boyter/scc/issues/379
Issue379Line=$(./scc -f csv "examples/issue379/" --no-scc-ignore | grep 'Python' | cut -d ',' -f 2)
Issue379Code=$(./scc -f csv "examples/issue379/" --no-scc-ignore | grep 'Python' | cut -d ',' -f 3)
Issue379Comments=$(./scc -f csv "examples/issue379/" --no-scc-ignore | grep 'Python' | cut -d ',' -f 4)
Issue379Blanks=$(./scc -f csv "examples/issue379/" --no-scc-ignore | grep 'Python' | cut -d ',' -f 5)
Issue379Complexity=$(./scc -f csv "examples/issue379/" --no-scc-ignore | grep 'Python' | cut -d ',' -f 6)
if [ $Issue379Line -ne 7 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue379 line counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue379Code -ne 4 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue379 code counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue379Comments -ne 2 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue379 comments counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue379Blanks -ne 1 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue379 blanks counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue379Complexity -ne 1 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue379 complexity counting"
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED Issue379 Regression Check"
fi

# Regression tests for https://github.com/boyter/scc/issues/564
Issue564GoCount=$(./scc -f csv "examples/issue564/" --no-scc-ignore | grep 'Go' | cut -d ',' -f 8)
Issue564PyCount=$(./scc -f csv "examples/issue564/" --no-scc-ignore | grep 'Python' | cut -d ',' -f 8)
Issue564GoExcludeCount=$(./scc -f csv "examples/issue564/" --no-scc-ignore --exclude-dir=level2 | grep 'Go' | cut -d ',' -f 8)
Issue564PyExcludeCount=$(./scc -f csv "examples/issue564/" --no-scc-ignore --exclude-dir=level2 | grep 'Python' | cut -d ',' -f 8)
Issue564GoExclude2Count=$(./scc -f csv "examples/issue564/" --no-scc-ignore --exclude-dir=level1 | grep 'Go' | cut -d ',' -f 8)
Issue564PyExclude2Count=$(./scc -f csv "examples/issue564/" --no-scc-ignore --exclude-dir=level1 | grep 'Python' | cut -d ',' -f 8)
Issue564GoExcludeMultiCount=$(./scc -f csv "examples/issue564/" --no-scc-ignore --exclude-dir=level1/level2 | grep 'Go' | cut -d ',' -f 8)
Issue564PyExcludeMultiCount=$(./scc -f csv "examples/issue564/" --no-scc-ignore --exclude-dir=level1/level2 | grep 'Python' | cut -d ',' -f 8)
if [ $Issue564GoCount -ne 2 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue564 Go file counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue564PyCount -ne 3 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue564 Python file counting"
    echo -e "=======================================================${NC}"
    exit
elif [ "$Issue564PyExcludeCount" != "" ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue564 exclude level2 Python file counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue564GoExcludeCount -ne 2 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue564 exclude level2 Go file counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue564PyExclude2Count -ne 1 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue564 exclude level1 Python file counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue564GoExclude2Count -ne 1 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue564 exclude level1 Go file counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue564GoExcludeMultiCount -ne 2 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue564 exclude level1/level2 Go file counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue564PyExcludeMultiCount -ne 1 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue564 exclude level1/level2 Python file counting"
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED Issue564 Regression Check"
fi

# Regression issue https://github.com/boyter/scc/issues/610
Issue610Line=$(./scc -f csv "examples/issue610/" --no-scc-ignore | grep 'TypeScript' | cut -d ',' -f 2)
Issue610Code=$(./scc -f csv "examples/issue610/" --no-scc-ignore | grep 'TypeScript' | cut -d ',' -f 3)
Issue610Comments=$(./scc -f csv "examples/issue610/" --no-scc-ignore | grep 'TypeScript' | cut -d ',' -f 4)
Issue610Blanks=$(./scc -f csv "examples/issue610/" --no-scc-ignore | grep 'TypeScript' | cut -d ',' -f 5)
Issue610Complexity=$(./scc -f csv "examples/issue610/" --no-scc-ignore | grep 'TypeScript' | cut -d ',' -f 6)
if [ $Issue610Line -ne 11 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue610 line counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue610Code -ne 7 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue610 code counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue610Comments -ne 2 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue610 comments counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue610Blanks -ne 2 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue610 blanks counting"
    echo -e "=======================================================${NC}"
    exit
elif [ $Issue610Complexity -ne 1 ] ; then
    echo -e "${RED}======================================================="
    echo -e "FAILED Issue610 complexity counting"
    echo -e "=======================================================${NC}"
    exit
else
    echo -e "${GREEN}PASSED Issue610 Regression Check"
fi

# Extra case for longer languages that are normally truncated
for i in 'CloudFormation (YAM' 'CloudFormation (JSO'
do
    if ./scc "examples/language/" --no-scc-ignore | grep -q "$i"; then
        echo -e "${GREEN}PASSED $i Language Check"
    else
        echo -e "${RED}======================================================="
        echo -e "FAILED Should be able to find $i"
        echo -e "=======================================================${NC}"
        exit
    fi
done

echo -e  "${NC}Checking compile targets..."

echo "   darwin..."
GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w"
GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w"
echo "   windows..."
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w"
GOOS=windows GOARCH=386 go build -ldflags="-s -w"
echo "   linux..."
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w"
GOOS=linux GOARCH=386 go build -ldflags="-s -w"
GOOS=linux GOARCH=arm64 go build -ldflags="-s -w"

echo -e "${NC}Cleaning up..."
rm ./scc
rm ./scc.exe
rm ./ignored.xml
rm .tmp_scc_yaml
rm ./examples/ignore/gitignorefile.txt
rm ./examples/ignore/ignorefile.txt

rm ./output.tab
rm ./output.wide
rm ./output.json
rm ./output2.json
rm ./output.csv
rm ./output.yaml
rm ./output.html
rm ./output.html2
rm ./output.sql
rm ./code.db


echo -e "${GREEN}================================================="
echo -e "ALL TESTS PASSED"
echo -e "=================================================${NC}"
