-include atlantis/$(STAGE).env

LAMBDA_BUCKET ?= $(STACK_NAME)
TEMPLATE_FILE ?= serverless-output.yaml

cf/bucket:
	aws s3 mb s3://$(LAMBDA_BUCKET)

cf/package:
	aws cloudformation package \
	  --template-file template.yaml \
	  --output-template-file $(TEMPLATE_FILE) \
	  --s3-bucket $(LAMBDA_BUCKET)

cf/plan:
	@aws cloudformation deploy \
	  --parameter-overrides BucketName=$(APK_BUCKET) FunctionName=$(STACK_NAME) \
	  --template-file $(TEMPLATE_FILE) \
	  --stack-name $(STACK_NAME) \
	  --capabilities CAPABILITY_IAM \
	  --no-execute-changeset 2>&1 | grep aws cloudformation describe-change-set | bash

cf/deploy:
	aws cloudformation deploy \
	  --parameter-overrides BucketName=$(APK_BUCKET) FunctionName=$(STACK_NAME) \
	  --template-file $(TEMPLATE_FILE) \
	  --stack-name $(STACK_NAME) \
	  --capabilities CAPABILITY_IAM

cf/destroy:
	-aws s3 rb s3://$(APK_BUCKET) --force
	-aws s3 rb s3://$(LAMBDA_BUCKET) --force
	aws cloudformation delete-stack --stack-name $(STACK_NAME)
	aws cloudformation wait stack-delete-complete --stack-name $(STACK_NAME)

aws/ssm:
	aws ssm put-parameter --region $(AWS_REGION) --name '/apk/rsa' --type 'SecureString' --value "`cat ops@cloudposse.com.rsa`"
	aws ssm put-parameter --region $(AWS_REGION) --name '/apk/key' --type 'String' --value 'ops@cloudposse.com.rsa.pub'

sync:
	aws s3 cp contrib/install.sh s3://$(APK_BUCKET)/install.sh
	aws s3 cp ops@cloudposse.com.rsa.pub s3://$(APK_BUCKET)/  
