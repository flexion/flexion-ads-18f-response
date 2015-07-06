Publicly accessible URL: http://pool3.18f.flexion.us

Github repository: https://github.com/flexion/flexion-ads-18f-response

Evaluation branch: master

# Approach used to create the prototype #

This project represents work done as a part of Flexion Inc.'s (http://flexion.us) response to GSA RFQ 4QTFHS150004 (Agile Delivery Services). Flexion Inc. is an enterprise IT advising, staffing and digital solutions company serving up lean and agile solutions.

Our choice of prototype was driven by personal experiences of friends, family and team members. Almost everyone has experienced the frustration of trying to comprehend unfamiliar diagnoses and drug names when dealing with disease or illness in themselves or a loved one. Whether speaking with a physician on the phone or in a physician’s office, it can be challenging to capture and retain drug names, understand their purpose and possible adverse effects, ask intelligent questions and make educated decisions. With existing subject matter expertise on the team, we decided to focus on anti-epileptic agents as our pharmaceutical category of interest, knowing we had access to interview subjects to help define and focus our requirements in a tool to help caregivers better understand anti-epileptic agents and the possible adverse effects associated with them. 

Driven by that need, we quickly researched, created and documented a primary persona to better focus all efforts on actual end user needs and goals. A project with a larger scope and longer timeline would typically have a longer definition phase with a larger group of research subjects to help us identify and document additional personas.

Given the abbreviated nature of the delivery, we rapidly assembled a cross-functional team with a clear leader and began developing the solution via approximately two-day iterations. This is shorter than our typical delivery cycle, which varies by client, but the work breakdown and general project flow is still representative of a typical iteration. In the absence of other constraining factors we would normally advocate for two-week iterations.

For ease of reviewing our integrated development process we have utilized the GitHub issue tracker, creating tasks for code review, design deliverables, acceptance criteria, infrastructure decisions, infrastructure implementation and of course feature development and test tasks.  If you are interested in understanding our process, the information there should provide good insight.  Since github tasks are not in the repository we have extracted a JSON view of them and 

We a model for development and design artifact workflow we used a develop branch and individual features merged via pull requests from feature-specific branches.  This was merged to master for evaluation purposes. Feature branches were merged after peer or project lead review and passing unit (Jasmine) and end-to-end (Protractor) tests. Continuous integration activity including automated testing was executed via a CircleCI cloud-based CI environment integrated into our GitHub repository.

Platform, architecture, technology and framework choices were made during an initial iteration 0 and informed by the constraints of the RFQ. We implemented a fundamentally responsive JavaScript solution with Bootstrap, AngularJS, CoffeeScript and Jade for the frontend and Node.js and Express for the backend. Data is accessed from https://open.fda.gov/drug/event/ in a RESTful manner.  At Flexion we are long-time advocates of commercially-hardened open source, and have used open technologies to create and host our prototype.  This prototype is released under a CC0 license as described in the LICENSE.md file and other components are licensed with MIT, MIT, Apache v2.0, BSD, GPL v2 and GPL v3 licenses.

Development-local test environments were automated using Grunt with a Dockerfile available for containerized testing when necessary. 

A publicly-accessible instance of the prototype is accessible using the url at the top of this document.  It is running in a Docker container on Amazon EC2 infrastructure, provisioned via the automated process documented in RUNNING.md file in the root of the repository.

The creation of this prototype was done in the typical Flexion manner: we take pride in our productivity and had a lot of fun delivering useful functionality in an agile, high-velocity manner as a high-functioning team using modern and open tools.  We appreciate the non-traditional approach manifested in this RFQ and are philosophically very aligned with its tenets.  We hope to be able to bring our agile skills to bear for the Federal government and 18F.
