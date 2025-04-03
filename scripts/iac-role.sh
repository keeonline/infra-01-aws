aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com

GITHUB_USER=keeonline
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws iam create-role --role-name IaC --assume-role-policy-document "{\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Federated\":\"arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com\"},\"Action\":\"sts:AssumeRoleWithWebIdentity\",\"Condition\":{\"StringEquals\":{\"token.actions.githubusercontent.com:aud\":\"sts.amazonaws.com\"},\"StringLike\":{\"token.actions.githubusercontent.com:sub\":[\"repo:${GITHUB_USER}/*:*\"]}}}]}"

aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --role-name IaC
