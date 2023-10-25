const AWS = require('aws-sdk');
const dynamoDB = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  try {
    if (!event.Records || !event.Records[0] || !event.Records[0].Sns || !event.Records[0].Sns.Message) {
      throw new Error('Invalid SNS message format');
    }

    const message = JSON.parse(event.Records[0].Sns.Message);
    
    const params = {
      TableName: 'my-table',
      Item: {
        id: new Date().toISOString(),
        message: message
      }
    };

    await dynamoDB.put(params).promise();

    return {
      statusCode: 200,
      body: JSON.stringify('Message saved to DynamoDB'),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify('An error occurred'),
    };
  }
};
