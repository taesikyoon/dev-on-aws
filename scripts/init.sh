#!/bin/bash

# 파라미터 스토어에서 값을 가져오는 명령어 입력
# 명령어로 가져온 파라미터 스토어로 sam에 파라미터를 동적으로 주도록한다.
check_command_success() {
    if [ $? -eq 0 ]; then
        echo "$1 성공"
    else
        echo "$1 실패"
        exit 1
    fi
}

# 스택 생성 상태를 주기적으로 확인하는 함수
wait_for_stack_completion() {
    echo "스택 생성 완료 대기중..."
    stack_name=$1
    while true; do
        status=$(aws cloudformation describe-stacks --stack-name ${stack_name} --query "Stacks[0].StackStatus" --output text 2>&1)
        
        if echo "$status" | grep -q "ValidationError"; then
            echo "스택을 찾을 수 없습니다. Error :"
            return 1
        elif [[ "$status" == "CREATE_COMPLETE" ]]; then
            echo "스택 생성이 완료되었습니다."
            return 0
        elif [[ "$status" == "CREATE_FAILED" || "$status" == "ROLLBACK_COMPLETE" || "$status" == "ROLLBACK_FAILED" ]]; then
            echo "스택 생성이 실패했습니다. 상태: $status"
            return 1
        else
            echo "[현재 상태: $status] 계속 대기 중..."
            sleep 10  # 30초마다 상태를 확인합니다.
        fi
    done
}


# 생성할 스택 이름을 입력.
read -p "생성할 스택의 이름을 적어주세요: " stack_name

cd ../templates

aws cloudformation create-stack --stack-name ${stack_name} --template-body file://cloudformation-setup.yaml --capabilities CAPABILITY_NAMED_IAM

# 스택 생성이 완료되기를 기다립니다.
wait_for_stack_completion ${stack_name}

# 생성된 스택에서 Lambda 실행 권한 ARN을 가져옵니다.
outputs=$(aws cloudformation describe-stacks --stack-name ${stack_name} --query "Stacks[0].Outputs")

# JSON 응답을 한 줄로 만들고 각 객체를 줄바꿈으로 분리
IFS=$'\n'
lines=$(echo "$outputs" | tr -d '\n' | sed 's/},/}\n/g')

# OutputKey와 OutputValue 추출
for line in $lines; do
    output_key=$(echo "$line" | sed -n 's/.*"OutputKey": "\([^"]*\)".*/\1/p')
    output_value=$(echo "$line" | sed -n 's/.*"OutputValue": "\([^"]*\)".*/\1/p')

    # 필요한 키에 따라 변수에 저장
    case "$output_key" in
        LambdaExecutionRoleARN)
            lambda_execution_role_arn="$output_value"
            ;;
        WebsiteBucketName)
            website_bucket_name="$output_value"
            ;;
        MP3BucketName)
            mp3_bucket_name="$output_value"
            ;;
    esac
done

# 결과 출력
check_command_success "스택 결과물 JSON으로 받아오기"

aws ssm put-parameter \
    --name "test-lambda-execution-role" \
    --value "${lambda_execution_role_arn}" \
    --type "SecureString" \
    --description "람다 실행 권한"

check_command_success "SSM에 Lambda 실행 권한 ARN를 저장"

# Lambda deployment
cd ../scripts && sh deploy-all-lambda.sh ${lambda_execution_role_arn} ${website_bucket_name} ${mp3_bucket_name}

# s3 bucket 전달
# lambda excution role 전달