REPORT_FILE="./quality_report.txt"
APP_PATH="./dist"

npm run lint
npm run test
npm audit


if [ $? -eq 0 ]; then
    echo "No problems found with code quality."
    exit 0
else
    echo "There were problems with code quality. See the report file for details."
    # Generate a report file with the results
    npm run lint --prefix $APP_PATH > $REPORT_FILE
    npm run test --prefix $APP_PATH >> $REPORT_FILE
    npm audit --prefix $APP_PATH >> $REPORT_FILE
    exit 1
fi