# API Gateway Lambda Proxy Integration Python Example


* API Gateway with Lambda Proxy Integration in Python sample code
* Remix version of several samples in the reference section
* Plus adding CloudWatch Logs and various updates


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
  "isBase64Encoded": false,
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  },
  "body": "{\"message\": \"Hello from Lambda!\"}"
}
```


## Test run from API Gateway

```bash
$ export URL=$(terraform output base_url)
$ curl $URL
{"message": "Hello from Lambda!"}
```


## Check the log

```bash
# show cloudwatch log group name
terraform output cloudwatch_log_group
```

* goto CloudWatch > Log Groups > API-Gateway-Execution-Logs_{rest-api-id}/{stage_name}
* click `Last Event Time` column to sort and check the latest entry


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
