ESCognitoStackName="devops-es-cognito"

$ aws cloudformation create-stack --stack-name $ESCognitoStackName --template-body file://cognito.yaml --capabilities CAPABILITY_NAMED_IAM
$ aws cloudformation describe-stacks --stack-name $ESCognitoStackName --output text | grep OUTPUTS | awk '{print $3"=\""$4"\""}'

UserPoolId="us-east-1_tkoHagXNb"
IdentityPoolId="us-east-1:3e3a6f16-2687-46ff-8724-be8cd5045fd9"
UserPoolArn="arn:aws:cognito-idp:us-east-1:307059479762:userpool/us-east-1_tkoHagXNb"
IdpDomain="$ESCognitoStackName"

$ aws cognito-idp create-user-pool-domain --user-pool-id $UserPoolId --domain $IdpDomain

ESStackName="devops-es"
LogBucketName="drumlogmanageres"
ElasticsearchDomainName="drumlogmanager"
ElasticsearchIndexName="drumlogmanagerindex"
FirehoseName="drumesfirehose"

$ aws cloudformation create-stack --stack-name $ESStackName --template-body file://es.yaml --parameters ParameterKey=LogBucketName,ParameterValue=$LogBucketName ParameterKey=ElasticsearchDomainName,ParameterValue=$ElasticsearchDomainName ParameterKey=ElasticsearchIndexName,ParameterValue=$ElasticsearchIndexName ParameterKey=FirehoseName,ParameterValue=$FirehoseName --capabilities CAPABILITY_NAMED_IAM

CognitoRoleName="CognitoAccessForAmazonES"
CognitoPolicyArn="arn:aws:iam::aws:policy/AmazonESCognitoAccess"
CognitoRoleArn=`aws iam get-role --role-name $CognitoRoleName --output text --query "Role.Arn"`

$ aws iam create-role --role-name $CognitoRoleName --assume-role-policy-document file://role.json                   
$ aws iam attach-role-policy --role-name $CognitoRoleName --policy-arn $CognitoPolicyArn
$ aws iam list-attached-role-policies --role-name $CognitoRoleName               

CognitoClientID=`aws cognito-idp list-user-pool-clients --user-pool-id $UserPoolId --output text --query "UserPoolClients[].ClientId"`
CognitoUserName="tuf@tuf.net"

$ aws cognito-idp admin-create-user --user-pool-id $UserPoolId --username $CognitoUserName --user-attributes=Name=email,Value=$CognitoUserName
