import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';

/**
 *
 * Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
 * @param {Object} event - API Gateway Lambda Proxy Input Format
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns {Object} object - API Gateway Lambda Proxy Output Format
 *
 */

export const lambdaHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    try {
        // 이벤트에서 UserId, NoteId, note를 받아서 비디에 저장하는 로직
        const { UserId, NoteId, note } = JSON.parse(event.body as string);

        const dynamodb = new DynamoDB.DocumentClient();

        const result = await dynamodb
            .put(
                {
                    TableName: 'notes',
                    Item: {
                        UserId,
                        NoteId,
                        note,
                    },
                },
                (err, data) => {
                    if (err) {
                        console.log('Error', err);
                    } else {
                        console.log('Success', data);
                    }
                },
            )
            .promise();

        // 데이터베이스에 저장이 성공했을 경우 저장 성공한 NoteID 반환

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'hello world',
                item: result.$response.data,
            }),
        };
    } catch (error) {
        console.log(error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: 'some error happened',
                error,
            }),
        };
    }
};
