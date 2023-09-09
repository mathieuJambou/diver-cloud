# Create an IAM user

aws iam create-user --user-name mj

# Create an IAM group

aws iam create-group --group-name MJGroup

# Add user to group

aws iam add-user-to-group --user-name mj --group-name MJGroup