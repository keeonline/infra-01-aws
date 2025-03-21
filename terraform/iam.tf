data "aws_iam_policy_document" "assume_role" {
  statement {
    actions               = ["sts:AssumeRole"]

    principals {
      type                = "Service"
      identifiers         = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_exec" {
    name                  = "${var.environment}-iam-role-ecs-task-exec"
    assume_role_policy    = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec" {
    role                  = aws_iam_role.ecs_task_exec.name
    policy_arn            = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
    name                  = "${var.environment}-iam-role-ecs-task"
    assume_role_policy    = data.aws_iam_policy_document.assume_role.json   
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
    role                  = aws_iam_role.ecs_task.name
    policy_arn            = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}