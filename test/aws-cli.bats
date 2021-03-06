#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/../modules/bash-commons/src/aws.sh"
load "test-helper"
load "aws-helper"

function setup {
  start_moto
}

function teardown {
  stop_moto
}

@test "aws_get_instance_tags empty" {
  run aws_get_instance_tags "fake-id" "us-east-1"
  assert_success

  local readonly expected=$(cat <<END_HEREDOC
{
  "Tags": []
}
END_HEREDOC
)

  assert_output_json "$expected"
}

@test "aws_get_instance_tags non-empty" {
  local readonly tag_key="foo"
  local readonly tag_value="bar"

  local instance_id
  instance_id=$(create_mock_instance_with_tags "$tag_key" "$tag_value")

  run aws_get_instance_tags "$instance_id" "us-east-1"
  assert_success

  local readonly expected=$(cat <<END_HEREDOC
{
   "Tags": [
     {
       "ResourceType": "instance",
       "ResourceId": "$instance_id",
       "Value": "$tag_value",
       "Key": "$tag_key"
     }
   ]
 }
END_HEREDOC
)

  assert_output_json "$expected"
}

@test "aws_describe_asg empty" {
  run aws_describe_asg "fake-asg-name" "us-east-1"
  assert_success

  local readonly expected=$(cat <<END_HEREDOC
{
  "AutoScalingGroups": []
}
END_HEREDOC
)

  assert_output_json "$expected"
}

@test "aws_describe_asg non-empty" {
  local readonly asg_name="foo"
  local readonly min_size=1
  local readonly max_size=3
  local readonly region="us-east-1"
  local readonly azs="${region}a"

  create_mock_asg "$asg_name" "$min_size" "$max_size" "$azs"

  run aws_describe_asg "$asg_name" "$region"
  assert_success

  local actual_asg_name
  actual_asg_name=$(echo "$output" | jq -r '.AutoScalingGroups[0].AutoScalingGroupName')
  assert_equal "$asg_name" "$actual_asg_name"

  local actual_min_size
  actual_min_size=$(echo "$output" | jq -r '.AutoScalingGroups[0].MinSize')
  assert_equal "$min_size" "$actual_min_size"

  local actual_max_size
  actual_max_size=$(echo "$output" | jq -r '.AutoScalingGroups[0].MaxSize')
  assert_equal "$max_size" "$actual_max_size"
}

@test "aws_describe_instances_in_asg empty" {
  run aws_describe_instances_in_asg "fake-asg-name" "us-east-1"
  assert_success

  local readonly expected=$(cat <<END_HEREDOC
{
  "Reservations": []
}
END_HEREDOC
)

  assert_output_json "$expected"
}

@test "aws_describe_instances_in_asg non-empty" {
  local readonly asg_name="foo"
  local readonly min_size=1
  local readonly max_size=3
  local readonly region="us-east-1"
  local readonly azs="${region}a"

  create_mock_asg "$asg_name" "$min_size" "$max_size" "$azs"

  run aws_describe_instances_in_asg "$asg_name" "$region"
  assert_success

  local num_instances
  num_instances=$(echo "$output" | jq -r '.Reservations | length')
  assert_greater_than "$num_instances" 0
}