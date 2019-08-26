# ES-Cognito Setup Process

Edit these or source from shell

```zsh
ESName="loghog"
CognitoUserName="tuf@tuf.net"
```

Create variables for Cognito and ES - no need to edit

```zsh
ESStackName="drumops-$ESName-es"
ElasticsearchDomainName="drumops$ESName"
ElasticsearchIndexName=""$ElasticsearchDomainName"index"
FirehoseName=""$ElasticsearchDomainName"firehose"
LogBucketName="$ElasticsearchDomainName"
ESCognitoStackName="$ESStackName-cog"
CognitoRoleName="CognitoAccessForAmazonES-$ESName"
CognitoPolicyArn="arn:aws:iam::aws:policy/AmazonESCognitoAccess"
IdpDomain="$ESCognitoStackName"
```

Create Cognito stack

```zsh
aws cloudformation create-stack --stack-name $ESCognitoStackName --template-body file://cognito.yaml --capabilities CAPABILITY_NAMED_IAM --output text
```

Generate variables from stack outputs we'll need for other commands below

```zsh
aws cloudformation describe-stacks --stack-name $ESCognitoStackName --output text | grep OUTPUTS | awk '{print $3 "," $4}' | while IFS=, read first last; do; export $first=$last; echo $first $last; done
```

Create Cognito domain

```zsh
aws cognito-idp create-user-pool-domain --user-pool-id $UserPoolId --domain $IdpDomain
```

Create Cognito role, add policies to the role, and create a user to log in with

```zsh
aws iam create-role --role-name $CognitoRoleName --assume-role-policy-document file://role.json
aws iam attach-role-policy --role-name $CognitoRoleName --policy-arn $CognitoPolicyArn
aws iam list-attached-role-policies --role-name $CognitoRoleName
CognitoRoleArn=`aws iam get-role --role-name $CognitoRoleName --output text --query "Role.Arn"`
CognitoClientID=`aws cognito-idp list-user-pool-clients --user-pool-id $UserPoolId --output text --query "UserPoolClients[].ClientId"`
aws cognito-idp admin-create-user --user-pool-id $UserPoolId --username $CognitoUserName --user-attributes=Name=email,Value=$CognitoUserName
```

Create ElasticSearch stack

```zsh
aws cloudformation create-stack --stack-name $ESStackName --template-body file://es.yaml --parameters ParameterKey=LogBucketName,ParameterValue=$LogBucketName ParameterKey=ElasticsearchDomainName,ParameterValue=$ElasticsearchDomainName ParameterKey=ElasticsearchIndexName,ParameterValue=$ElasticsearchIndexName ParameterKey=FirehoseName,ParameterValue=$FirehoseName --capabilities CAPABILITY_NAMED_IAM
```

Turn Cognito auth on for ES

```zsh
aws es update-elasticsearch-domain-config --domain-name $ElasticsearchDomainName --cognito-options Enabled=true,UserPoolId="$UserPoolId",IdentityPoolId="$IdentityPoolId",RoleArn="$CognitoRoleArn"
```
