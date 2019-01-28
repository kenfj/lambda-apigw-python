# API Gateway Lambda Proxy Integration Python Example


* API Gateway with Lambda Proxy Integration in Python sample code
* Remix version of several samples in the reference section
* Plus adding CloudWatch Logs and use official SAM framework


<p align="center">
<img src="https://user-images.githubusercontent.com/44661517/51655362-ad77fa00-1fdf-11e9-82f2-f5fb6a4d1120.png" width="500">
</p>


## How to run

```bash
terraform apply
```


## Test run Lambda

```bash
$ aws lambda invoke \
    --region ap-northeast-1 \
    --function-name lambda-api-gw output.txt
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
$ cat output.txt | jq
{
  "statusCode": 200,
  "body": "{\"message\": \"hello world\", \"location\": \"1x.2xx.3x.1xx\"}"
}
```


## Test run from API Gateway

```bash
$ export URL=$(terraform output base_url)
$ curl $URL
{"message": "hello world", "location": "1x.2xx.3x.1xx"}
```


## Check the log

```bash
# show cloudwatch log group name
terraform output cloudwatch_log_group
```

* goto CloudWatch > Log Groups > API-Gateway-Execution-Logs_{rest-api-id}/{stage_name}
* click `Last Event Time` column to sort and check the latest entry


## Use SAM to create and run app locally

### install SAM and create SAM app

```bash
# install SAM
brew tap aws/tap
brew install aws-sam-cli
# create sam-app directory
sam init --runtime python3.6

# edit sam-app/hello_world/app.py
```

### test and deploy

```bash
cd sam-app/

# create virtual env
python3 -m venv .venv
. .venv/bin/activate
pip install --upgrade pip
pip install -r hello_world/requirements.txt
pip install pytest pytest-mock

# run test
export greeting=hello
python -m pytest tests/ -v

# build SAM app
# - this command will download 2GB docker image at first time
# - and create sam-app/.aws-sam/build/HelloWorldFunction
sam build --use-container --region ap-northeast-1
# run locally
sam local start-api --region ap-northeast-1
open http://127.0.0.1:3000/hello

# stop virtual env
deactivate

# now ready to run terraform apply
```


## Clean up

* note: the CloudWatch Log Group need to be deleted manually

```bash
terraform destroy
```


## Reference

* https://learn.hashicorp.com/terraform/aws/lambda-api-gateway
  - note in the section "Allowing API Gateway to Access Lambda"
  - `function_name = "${aws_lambda_function.example.arn}"` should be
  - `function_name = "${aws_lambda_function.example.function_name}"`
* https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples/lambda
* https://qiita.com/baikichiz/items/2de7c4c0dcf9b051037a
* https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/
