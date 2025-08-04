#  Step-by-Step Challenge
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