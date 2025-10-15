#  Step-by-Step Challenge Part 1: Basic VPC Infrastructure
## Step 1: Define Structured Input Variables
- Create a variable to represent your VPC configuration (e.g., name, CIDR block).
- Create a nested map or object variable to represent subnet configurations:
    - Include subnet type (public or private)
    - CIDR block
    - Availability zone
    - Optional metadata (e.g., tags or route table association flags)

**Goal:** Practice declaring and referencing nested maps or objects.

## Step 2: Transform Subnet Data for Resource Creation
- Use for_each to loop over the subnet definitions.
- Apply list or map comprehension to:
    - Filter public vs. private subnets
    - Extract subnet IDs for route table associations
    - Build dynamic tags or naming conventions

**Goal:** Practice flattening and filtering nested structures for use in resource blocks.

## Step 3: Create VPC and Subnets
- Create the VPC using the input variable.
- Create subnets using the transformed data structure.
- Ensure each subnet is tagged and placed in the correct AZ.

**Goal:** Validate that your data structure drives subnet creation cleanly.

## Step 4: Routing and Gateways
- Create an Internet Gateway and attach it to the VPC.
- Create a NAT Gateway in one of the public subnets.
- Create route tables for public and private subnets.
- Use for_each to associate route tables with the correct subnets.

**Goal:** Use subnet metadata to drive conditional associations.

## Step 5: Outputs
- Output the VPC ID, subnet IDs (grouped by type), and route table IDs.
- Optionally output the NAT Gateway ID and Elastic IP.

**Goal:** Practice using output blocks with dynamic references and filtered lists.

### Bonus Challenges
- Add a conditional flag to enable/disable NAT Gateway creation.
- Modularize the VPC and subnet logic into reusable modules.
- Use locals to simplify complex expressions or derived values.

---
   <br>   
   <br>   

# Step-by-Step Challenge Part 2: EC2 Placement and Network Alignment
## Step 6: Define EC2 Instance Configuration
Create a new input variable to define EC2 instances:
- Instance name or role
- Subnet key (where it should be placed)
- Instance type
- Optional metadata (e.g., tags, user data, security group references)

**Goal:** Practice declaring structured instance configs and referencing subnet placement.

## Step 7: Transform Instance Data for Placement
Use locals to:
- Validate that each instance references a valid subnet
- Group instances by subnet type or AZ
- Build dynamic tags and naming conventions

**Goal:** Practice filtering and validating instance placement logic.

## Step 8: Create EC2 Instances
Use for_each to create EC2 instances from the transformed data.
- Reference subnet ID from your existing subnet map
- Attach security groups (can be static or derived later)
- Inject user data if provided

**Goal:** Validate that your instance config drives clean, narratable resource creation.

## Step 9: Security Groups
Create security groups for public and private instances:
- Public: allow SSH/HTTP from the internet
- Private: allow internal traffic only
Use locals to:
- Assign security groups based on subnet type
- Validate that each instance has a security group

**Goal:** Practice conditional resource creation and dynamic association.

## Step 10: Outputs
Output:
- EC2 instance IDs grouped by subnet type or AZ
- Private IPs for internal reference
- Security group IDs

**Goal:** Surface narratable infrastructure state for debugging or downstream use.

## Bonus Challenges
|Challenge|Goal|
|----|----|
|Validate instance placement in subnets with route tables | Practice diagnostic locals|
|Surface instances placed in subnets without IGW or NAT	| Reinforce semantic alignment|
|Inject templated user data based on instance role	| Practice dynamic string interpolation|
|Add lifecycle rules or EBS volume attachments	| Extend resource modeling idioms|
