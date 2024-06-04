# Create
aws cloudformation create-stack --stack-name developer-on-aws --template-body file://cloudformation-setup.yaml --capabilities CAPABILITY_NAMED_IAM

# Delete
aws cloudformation delete-stack --stack-name developer-on-aws

# Validate
aws cloudformation validate-template --template-body file://cloudformation-setup.yaml

# Describe
aws cloudformation describe-stack-events --stack-name developer-on-aws

# SAM Local Test
sam local start-api

# SAM Build
sam build

# SAM Deploy
sam deploy --guided