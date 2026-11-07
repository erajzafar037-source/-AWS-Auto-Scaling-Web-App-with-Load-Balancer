{
  "widgets": [
    { "type": "metric", "x": 0, "y": 0, "width": 12, "height": 6,
      "properties": { "title": "ALB Request Count", "region": "${region}", "stat": "Sum", "period": 60,
        "metrics": [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${alb}"]] } },
    { "type": "metric", "x": 12, "y": 0, "width": 12, "height": 6,
      "properties": { "title": "HTTP Errors (5xx / 4xx)", "region": "${region}", "stat": "Sum", "period": 60,
        "metrics": [["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${alb}"],
                    ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "${alb}"]] } },
    { "type": "metric", "x": 0, "y": 6, "width": 12, "height": 6,
      "properties": { "title": "Target Response Time (p95)", "region": "${region}", "stat": "p95", "period": 60,
        "metrics": [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${alb}"]] } },
    { "type": "metric", "x": 12, "y": 6, "width": 12, "height": 6,
      "properties": { "title": "Healthy / Unhealthy Hosts", "region": "${region}", "stat": "Average", "period": 60,
        "metrics": [["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${tg}", "LoadBalancer", "${alb}"],
                    ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", "${tg}", "LoadBalancer", "${alb}"]] } },
    { "type": "metric", "x": 0, "y": 12, "width": 12, "height": 6,
      "properties": { "title": "ASG CPU Utilization", "region": "${region}", "stat": "Average", "period": 60,
        "metrics": [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${asg}"]] } },
    { "type": "metric", "x": 12, "y": 12, "width": 12, "height": 6,
      "properties": { "title": "ASG Desired vs In-Service", "region": "${region}", "stat": "Average", "period": 60,
        "metrics": [["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", "${asg}"],
                    ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${asg}"]] } }
  ]
}
