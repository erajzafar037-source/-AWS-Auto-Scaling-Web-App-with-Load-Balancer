const pptxgen = require("pptxgenjs");
const pres = new pptxgen();
pres.layout = "LAYOUT_16x9";
pres.title = "AWS Auto-Scaling Web App";
const NAVY="16202E", ORANGE="FF9900", LIGHT="F4F6F8", INK="1F2A37", MUTE="5B6776", WHITE="FFFFFF";
const F="Calibri";

function base(title, n){
  const s = pres.addSlide(); s.background={color:LIGHT};
  s.addShape(pres.ShapeType.rect,{x:0,y:0,w:10,h:0.9,fill:{color:NAVY}});
  s.addShape(pres.ShapeType.rect,{x:0,y:0.9,w:10,h:0.05,fill:{color:ORANGE}});
  s.addText(title,{x:0.5,y:0.1,w:9,h:0.7,fontFace:F,fontSize:26,bold:true,color:WHITE,isTextBox:true,margin:0,valign:"middle"});
  s.addText(String(n),{x:9.2,y:5.2,w:0.5,h:0.3,fontFace:F,fontSize:10,color:MUTE,align:"right",isTextBox:true,margin:0});
  return s;
}
function bullets(s, items, o={}){
  s.addText(items.map((t,i)=>({text:t,options:{bullet:true,breakLine:i<items.length-1,paraSpaceAfter:8}})),
   Object.assign({x:0.5,y:1.3,w:9,h:3.7,fontFace:F,fontSize:18,color:INK,valign:"top",isTextBox:true,margin:0},o));
}
function box(s,x,y,w,h,label,sub,fill,fc){
  s.addShape(pres.ShapeType.roundRect,{x,y,w,h,fill:{color:fill},line:{color:fill},rectRadius:0.08});
  s.addText([{text:label,options:{bold:true,fontSize:14,breakLine:!!sub}},...(sub?[{text:sub,options:{fontSize:10}}]:[])],
    {x,y,w,h,fontFace:F,color:fc||WHITE,align:"center",valign:"middle",isTextBox:true,margin:4});
}

// 1 Title
let s = pres.addSlide(); s.background={color:NAVY};
s.addShape(pres.ShapeType.rect,{x:0.6,y:2.0,w:0.12,h:1.5,fill:{color:ORANGE}});
s.addText("AWS Auto-Scaling Web App",{x:0.95,y:1.9,w:8.5,h:0.9,fontFace:F,fontSize:40,bold:true,color:WHITE,isTextBox:true,margin:0});
s.addText("with Application Load Balancer, Terraform & zero-downtime deploys",{x:0.95,y:2.8,w:8.5,h:0.6,fontFace:F,fontSize:20,color:"D5DBE3",isTextBox:true,margin:0});
s.addText("FastAPI · ALB · ASG · Terraform · Packer · GitHub Actions · CloudWatch",{x:0.95,y:3.6,w:8.5,h:0.4,fontFace:F,fontSize:14,color:ORANGE,isTextBox:true,margin:0});
s.addNotes("Intro: a production-style, highly available, auto-scaling web tier fully defined as code.");

// 2 Objective
s = base("Objective",2);
bullets(s,["Highly available web app: ALB in front of a multi-AZ Auto Scaling Group","All infrastructure in modular Terraform (VPC, ALB, ASG, monitoring)","Rolling deployments with zero downtime via golden AMIs","CloudWatch dashboard and alarms for ALB and ASG","CI/CD in GitHub Actions: test, bake AMI, apply, verify"]);
s.addNotes("Audience: AWS DevOps / cloud engineers. Shows resilience and automation.");

// 3 Architecture
s = base("Architecture",3);
box(s,0.4,2.3,1.2,0.9,"Users",null,"E3E8EE",INK);
box(s,2.1,2.2,1.9,1.1,"ALB","HTTPS · ACM · /health",ORANGE,NAVY);
s.addShape(pres.ShapeType.roundRect,{x:4.6,y:1.2,w:3.3,h:3.5,fill:{color:"E3E8EE"},line:{color:"B8C2CE"},rectRadius:0.1});
s.addText("Private subnets (2 AZs)",{x:4.6,y:1.25,w:3.3,h:0.35,fontFace:F,fontSize:12,bold:true,color:MUTE,align:"center",isTextBox:true,margin:0});
box(s,4.9,1.7,2.7,0.9,"EC2 · AZ-a","FastAPI :8000 (ASG)",NAVY);
box(s,4.9,2.8,2.7,0.9,"EC2 · AZ-b","FastAPI :8000 (ASG)",NAVY);
box(s,4.9,3.85,2.7,0.7,"scale 2 → 6",null,"3B4A5E");
box(s,8.3,2.2,1.4,1.1,"CloudWatch","metrics · logs · alarms","5B6776");
[[1.6,2.75,2.1],[4.0,2.75,4.6]].forEach(([x,y,xe])=>s.addShape(pres.ShapeType.line,{x,y,w:xe-x>1?0.55:0.5,h:0,line:{color:INK,width:2,endArrowType:"triangle"}}));
s.addShape(pres.ShapeType.line,{x:7.9,y:2.75,w:0.4,h:0,line:{color:MUTE,width:1.5,dashType:"dash",endArrowType:"triangle"}});
s.addText("Instances sit in private subnets; only the ALB security group can reach port 8000. IAM role (no keys) ships metrics and logs.",{x:0.5,y:4.85,w:8.2,h:0.45,fontFace:F,fontSize:12,color:MUTE,isTextBox:true,margin:0});
s.addNotes("Traffic: users -> ALB (TLS terminates) -> healthy instances across two AZs. NAT gateway provides outbound access for private subnets.");

// 4 Terraform
s = base("Infrastructure as Code",4);
bullets(s,["modules/vpc: terraform-aws-modules/vpc, public + private subnets, NAT","modules/alb: SG, HTTPS listener, HTTP→HTTPS redirect, target group","modules/asg: launch template, IAM role, SG, instance refresh, scaling policies","modules/monitoring: dashboard, alarms, SNS","Remote state: S3 + DynamoDB locking; outputs include the ALB DNS name"]);
s.addNotes("Modular layout so VPC, compute and monitoring can evolve and be reused independently.");

// 5 Rolling deploy
s = base("Zero-Downtime Rolling Deployment",5);
const steps=[["1","New AMI","Packer bake"],["2","New LT version","terraform apply"],["3","Instance refresh","launch new first"],["4","Health gate","ALB /health"],["5","Drain & retire","30s draining"]];
steps.forEach((st,i)=>{
  const x=0.4+i*1.85;
  s.addShape(pres.ShapeType.ellipse,{x:x+0.55,y:1.35,w:0.6,h:0.6,fill:{color:ORANGE}});
  s.addText(st[0],{x:x+0.55,y:1.35,w:0.6,h:0.6,fontFace:F,fontSize:18,bold:true,color:NAVY,align:"center",valign:"middle",isTextBox:true,margin:0});
  s.addText(st[1],{x,y:2.05,w:1.7,h:0.4,fontFace:F,fontSize:14,bold:true,color:INK,align:"center",isTextBox:true,margin:0});
  s.addText(st[2],{x,y:2.45,w:1.7,h:0.4,fontFace:F,fontSize:11,color:MUTE,align:"center",isTextBox:true,margin:0});
});
s.addShape(pres.ShapeType.roundRect,{x:0.5,y:3.2,w:9,h:1.7,fill:{color:WHITE},line:{color:"D5DBE3"},rectRadius:0.08});
s.addText([{text:"min_healthy_percentage = 100",options:{bullet:true,breakLine:true}},{text:"max_healthy_percentage = 200  (surge capacity)",options:{bullet:true,breakLine:true}},{text:"Pipeline waits on the refresh, then asserts every instance runs the new version",options:{bullet:true}}],
  {x:0.8,y:3.3,w:8.4,h:1.5,fontFace:F,fontSize:16,color:INK,valign:"middle",isTextBox:true,margin:0,paraSpaceAfter:6});
s.addNotes("Capacity never dips below current: new instances are launched and warmed before old ones are terminated.");

// 6 Scaling
s = base("Auto Scaling Policies",6);
s.addTable([
  [{text:"Policy",options:{bold:true,color:WHITE,fill:{color:NAVY}}},{text:"Target",options:{bold:true,color:WHITE,fill:{color:NAVY}}},{text:"Why",options:{bold:true,color:WHITE,fill:{color:NAVY}}}],
  ["Avg CPU (target tracking)","60%","Handles compute-bound load"],
  ["ALB requests per target","500","Scales on traffic, not just CPU"],
  ["Capacity bounds","min 2 / max 6","One instance per AZ minimum"],
  ["Health checks","ELB, 120s grace","Replace instances failing /health"],
],{x:0.5,y:1.3,w:9,colW:[3.2,2.2,3.6],fontFace:F,fontSize:15,color:INK,border:{type:"solid",color:"D5DBE3",pt:1},fill:{color:WHITE},rowH:0.5});
s.addText("Target tracking replaces the classic “out at 70% / in at 30%” step policy and avoids flapping.",{x:0.5,y:4.2,w:9,h:0.6,fontFace:F,fontSize:14,italic:true,color:MUTE,isTextBox:true,margin:0});
s.addNotes("Mention step scaling as an alternative, plus Spot via a mixed instances policy.");

// 7 CI/CD
s = base("CI/CD Pipeline (GitHub Actions)",7);
const st2=[["Test","pytest"],["Validate","fmt · validate"],["Bake AMI","Packer"],["Apply","Terraform"],["Verify","integration tests"]];
st2.forEach((t,i)=>{ const x=0.4+i*1.85;
  box(s,x,1.5,1.65,1.0,t[0],t[1],i<2?"3B4A5E":(i<4?NAVY:ORANGE),i===4?NAVY:WHITE);
  if(i<4) s.addShape(pres.ShapeType.line,{x:x+1.65,y:2.0,w:0.2,h:0,line:{color:INK,width:2,endArrowType:"triangle"}});
});
bullets(s,["Pull requests: test + terraform validate only","Merge to main: bake AMI → apply behind an environment approval gate","AWS access via OIDC role, no stored keys"],{y:3.0,h:1.9,fontSize:16});
s.addNotes("Production environment can require reviewers for manual approval.");

// 8 Monitoring
s = base("Monitoring & Alarms",8);
s.addText("Dashboard",{x:0.5,y:1.2,w:4.2,h:0.4,fontFace:F,fontSize:18,bold:true,color:ORANGE,isTextBox:true,margin:0});
s.addText(["ALB request count","HTTP 4xx / 5xx","p95 target latency","Healthy vs unhealthy hosts","ASG CPU","Desired vs in-service capacity"].map((t,i,a)=>({text:t,options:{bullet:true,breakLine:i<a.length-1}})),{x:0.5,y:1.65,w:4.2,h:3,fontFace:F,fontSize:16,color:INK,valign:"top",isTextBox:true,margin:0,paraSpaceAfter:5});
s.addText("Alarms → SNS",{x:5.2,y:1.2,w:4.3,h:0.4,fontFace:F,fontSize:18,bold:true,color:ORANGE,isTextBox:true,margin:0});
s.addText(["Target 5xx > 10 per min for 3 min","ASG CPU > 80% for 5 min","Any unhealthy host for 2 min"].map((t,i,a)=>({text:t,options:{bullet:true,breakLine:i<a.length-1}})),{x:5.2,y:1.65,w:4.3,h:2,fontFace:F,fontSize:16,color:INK,valign:"top",isTextBox:true,margin:0,paraSpaceAfter:5});
s.addText("Validate with ApacheBench against /cpu to watch scale-out live.",{x:5.2,y:3.8,w:4.3,h:0.8,fontFace:F,fontSize:14,italic:true,color:MUTE,isTextBox:true,margin:0});
s.addNotes("Dashboard JSON lives in the monitoring module; alarms are defined in Terraform.");

// 9 Security
s = base("Security",9);
bullets(s,["Private subnets; instance SG accepts traffic only from the ALB SG","IAM instance profile for CloudWatch and SSM; no embedded AWS keys","IMDSv2 required; SSM Session Manager instead of SSH","ACM certificate with TLS 1.3 policy; HTTP redirected to HTTPS","OIDC from GitHub to AWS; encrypted, locked Terraform state"]);
s.addNotes("Least privilege, no long-lived credentials anywhere.");

// 10 Talking points
s = base("Interview Talking Points",10);
bullets(s,["HA: ALB health checks + multi-AZ ASG tolerate instance and AZ failure","Rolling refresh vs blue/green (two ASGs + weighted Route 53)","Challenges: warmup time, grace period, connection draining","Cost levers: Spot mixed instances, single vs per-AZ NAT, scheduled scaling","Next steps: containers on ECS/EKS, WAF, RDS Multi-AZ, auto-rollback on alarms"]);
s.addNotes("Tie each point to a specific line of Terraform in the repo.");

pres.writeFile({fileName:"aws-autoscaling-webapp.pptx"}).then(()=>console.log("ok"));
