# Automated Architecture Governance and AI-Driven Refactoring: Verification Strategies and Enterprise Best Practices in All-AI Coding Environments

## Abstract

As Large Language Model (LLM) capabilities improve, software development paradigms are undergoing a profound transformation from "humans write code" to "AI generates, humans review" and even "All-AI Coding". However, when handling complex architecture-level refactoring tasks, the all-AI coding model faces serious reliability challenges, most typically manifested as the "Recursive Repair Loop": AI-generated fixes are reviewed by AI, reviews find new errors, fixes after review find more errors, causing code quality to oscillate without convergence. This phenomenon reveals the fundamental limitations of current probability-based "AI review" in the absence of deterministic anchors (Deterministic Ground Truth).

This report aims to deeply explore this technical bottleneck and propose an enterprise-level solution based on "Architecture-as-Code" and "Test-Driven Refactoring" for development environments where manual code review is not possible. The report first analyzes the pathological characteristics of LLMs in self-correction and recursive reasoning from a theoretical level, demonstrating why relying solely on AI review is not feasible at the architecture level. Then, it elaborates in detail how to use tools like ArchUnit and NetArchTest to build executable Architectural Fitness Functions that verify the completeness of repair plans with mathematical certainty. Finally, combined with cutting-edge tools like Cursor, Aider, and SonarQube, it constructs an automated governance pipeline that requires no human intervention in code details, providing a systematic implementation path for software quality assurance in the all-AI coding era.

---

## 1. Pathological Analysis of Recursive Repair Loops: Why AI Cannot Review AI

In all-AI coding workflows, the core pain point users encounter is the infinite loop of "fix->review->fix again". To solve this problem, we must first understand the cognitive science and computational linguistics mechanisms that cause this phenomenon. This is not simply a prompt engineering problem, but rather a systematic failure when probability models lack external feedback signals in closed loops.

### 1.1 Probabilistic Verification and Hallucination Amplification

Traditional code review relies on human experts' mental models, which are built on deterministic understanding of logical reasoning, domain knowledge, and runtime behavior. In contrast, LLM "review" is essentially **next token prediction** based on training data.

When AI is asked to "review" code, it is not building an Abstract Syntax Tree (AST) of the code or simulating execution paths, but rather simulating the language patterns of a "code reviewer". In training corpora (such as GitHub Pull Requests), review comments usually contain criticism and modification suggestions. Therefore, the model has a statistical **critique bias**: to play the role of "reviewer" well, it tends to find problems, even if the code is functionally correct. This tendency leads to the generation of "hallucinated bugs", such as claiming an already imported variable is undefined, or misjudging style preferences as logical defects.

In recursive loops, hallucinated errors from the first round of review are treated as real requirements that must be resolved by the second round of repair Agent, thus modifying originally correct code. Such modifications often break the original logical structure, causing the third round of review to find real regression errors. Thus repeating, code entropy increases rather than decreases.

### 1.2 Sycophancy Effect and Context Collapse

Research shows that LLMs exhibit significant **sycophancy behavior**, i.e., they tend to conform to users' implicit biases or established premises in context.

- **Regressive Sycophancy:** When users or preceding Agents point out "there is an error here", current AI models, even when faced with correct code, tend to acknowledge the error and try to "fix" it. This conformity to erroneous premises is a key psychological dynamic factor causing repair loops to not converge.

- **Context Collapse:** Architecture refactoring involves global dependency relationships. However, LLMs are limited by context windows and often can only focus on currently edited file fragments. When "fixing file A", AI may forget that this modification broke the contract in "file B". When the review Agent looks at file B, discovers the broken contract, and requests a fix, this in turn breaks file A. This oscillation of local optima due to lack of a global consistency view is the main cause of failure in large refactoring tasks.


### 1.3 Limitations of Intrinsic Self-Correction

Although the industry has high hopes for AI's self-reflection, empirical research shows that without external tools (such as compilers, interpreters, test results), LLM's **intrinsic self-correction** capability is extremely limited and may even lead to performance degradation.

|**Characteristic**|**Human Review**|**AI Review (LLM)**|
|---|---|---|
|**Verification Mechanism**|Logical reasoning + experience judgment|Pattern matching + probability prediction|
|**Error Identification**|Based on causal relationships|Based on text statistical features|
|**Context Awareness**|Global/system-level|Local/window-limited|
|**Response to Criticism**|Dialectical analysis|Tends to conform (sycophancy)|
|**Result Stability**|High|Low (randomness)|

**Conclusion:** In architecture governance, using probabilistic AI to verify probabilistic AI output is mathematically non-convergent. **Deterministic anchors** must be introduced -- i.e., compiler errors, test failures, static analysis reports -- to break this loop.

### 1.4 Input Principles to Avoid "Same-Source Fallacy"

In multi-Agent collaborative all-AI development flows, the most dangerous closed loop is "generate tests based on implementation plan, then generate code based on the same plan". If tests and code share the same input document, the verification loop completely fails. To this end, System Prompts must guide each Agent to follow these "truth source" isolation strategies:

- **Test Generation Source (Verifier Input):** Only allow extracting acceptance criteria from "Architecture Design Document" or "Requirements Specification" to generate ArchUnit rules and integration tests. Test Agent is strictly forbidden from referencing any detailed implementation plan (Plan), to maintain the "client acceptance" perspective independence.
- **Code Generation Source (Coder Input):** Only reference "Implementation Plan Document", real-time test errors, and source code itself. Implementation details should align with test feedback, not reverse-influence tests.
- **Conflict Resolution Guidelines:** When implementation conflicts with tests, design-document-driven tests are the "Golden Truth". Implementation must compromise to the design intent described by tests, not modify tests to accommodate implementation.

By reinforcing section 1.4 above in System Prompts, "test-implementation" can form true orthogonal verification without increasing human involvement, rather than a self-verification loop.

---

## 2. Dual Anchors: Architecture and Behavior

Addressing the first core question raised by users: **"Can we write a complete test suite to check if the repair plan is complete?"**

The answer is **yes**. But the "test suite" here is not traditional unit tests, but **Architectural Fitness Functions**. This is a technique that encodes architecture rules into executable tests, capable of verifying with mathematical precision whether system structure conforms to expected design blueprints.

### 2.1 Structural Anchors: Architectural Fitness Functions (ArchUnit)

Architectural fitness functions originate from evolutionary architecture theory, designed to measure the fit between system architecture and preset goals. In all-AI coding environments, they serve as "automated architects", verifying not just functionality, but structure.

Main tool ecosystem includes:

- **ArchUnit (Java):** Industry standard tool that verifies package dependencies, class inheritance, annotation usage rules by analyzing Java bytecode. It doesn't depend on source code text, thus robust to AI-generated format errors.

- **NetArchTest (.NET):** Fluent API designed specifically for .NET ecosystem, used to enforce layered architecture and dependency rules.

- **Dependency-Cruiser / TsArch (JavaScript/TypeScript):** For frontend and Node.js environments, verifies module dependency graphs by parsing Abstract Syntax Trees (AST).

- **ArchUnitNET:** ArchUnit's .NET port, providing cross-language architecture governance capabilities.

**SaaS Upgrade Specific Rules:** In multi-tenant environments, structural anchors must further include RLS (Row-Level Security) policies, tenant annotations (e.g., `@TenantAware`), and cross-domain isolation boundary detection. By adding rules like "all repositories accessing `tenant_data` need `@TenantAware` annotation", "shared services forbidden from directly referencing tenant-specific schema" in ArchUnit/NetArchTest, tenant isolation can be forcibly verified as not broken during upgrades.


### 2.2 Behavioral Anchors: Black-Box Contract Tests

Correct structure doesn't mean trustworthy external behavior. To extend the scope of "deterministic anchors", Test Agent must translate API definitions, data flows, and side effects from design documents into contract-level integration tests:

- **Look only at contracts, not implementation:** Test logic only depends on "Architecture Design Document" or "Requirements Specification". It doesn't depend on class names, method names, and other Plan details, thus allowing code implementation to evolve freely.
- **HTTP/message-driven verification:** Trigger the system through real interface calls, verify HTTP status codes, Response Body, and record changes in key database tables (e.g., `audit_logs`, `tenant_events`).
- **Observable side effects:** Establish assertions for external side effects like audit logs, event buses, RLS policies, ensuring behaviors like "tenant_id is written", "audit record lands" are consistent with design contracts.
- **Example:** `POST /impersonate` must insert an `IMPERSONATE_START` record in the database, regardless of whether the backend uses `ServiceA` or `ServiceB`.

Only when behavioral anchor black-box contract tests and structural anchor ArchUnit rules both pass can we confirm that both "correct external behavior + correct internal structure" dual anchors are satisfied.

### 2.3 Converting Repair Plans into Executable Acceptance Criteria

In traditional development models, architecture repair plans are usually a document (e.g., "decouple order service from inventory database"). In all-AI mode, this document must be converted into **architecture test code**.

**Operational Process:**

1. **Plan Parsing:** AI Architect Agent analyzes current architecture defects (e.g.: circular dependencies, layering violations).

2. **Rule Generation:** Write ArchUnit rules describing the "ideal state after repair".

    - _Defect Description:_ "UI layer directly calls data layer."

    - _ArchUnit Rule:_ `noClasses().that().resideIn("..ui..").should().dependOnClassesThat().resideIn("..data..")`

3. **Red/Green Loop:** Run these tests before repair begins, they should **fail (Red)**. This failure proves that tests accurately capture current architecture defects.

4. **Verify Completeness:** Only when all these tests **pass (Green)** is the repair plan considered structurally complete.


### 2.4 Strategies for Verifying "Completeness"

Users worry about "whether the repair plan is complete". Architecture tests provide a stricter definition of "complete" than manual review:

- **Full Scan:** Architecture tests scan all compiled classes. If the repair plan misses any hidden class file (e.g., AI fixed 99 files, missed 1), ArchUnit will immediately error. Humans easily fatigue and miss when reviewing hundreds of files, but machines don't.

- **Prevent Regression:** Once repair is complete, these tests are kept in the CI pipeline. If future AI modifications accidentally reintroduce old architecture defects, the build will automatically fail. This mechanism is called **Architectural Ratchet**.


**Example: Layered Architecture Verification Code (Java/ArchUnit)**

```java
@ArchTest
public static final ArchRule layered_architecture_must_be_respected =
    layeredArchitecture()
       .consideringOnlyDependenciesInAnyPackage("com.myapp..")
       .layer("Controller").definedBy("..controller..")
       .layer("Service").definedBy("..service..")
       .layer("Persistence").definedBy("..persistence..")

       .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
       .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller")
       .whereLayer("Persistence").mayOnlyBeAccessedByLayers("Service");
```

This code segment defines a strict unidirectional dependency rule. If AI-generated code has Service reverse-calling Controller, or Controller skipping Service to directly call Persistence, the test will fail directly. This provides a binary, unambiguous judgment standard for "whether repair is complete".

---

## 3. Enterprise Best Practices: Unattended Governance Pipeline

Addressing the second question from users: **"What are enterprise best practices (when unable to manually review code)?"**

Under constraints where manual code review is not possible, the core concept of enterprise governance must shift from **"Trust by Observation"** to **"Trust by Constraint"**. This means we need to build an automated system where AI Agent code can only be merged after meeting a series of strict mechanical checks.

This system consists of four pillars: Test-Driven Refactoring, Legacy Code Snapshots (Snapshot Testing), Static Analysis Gates, and Agentic Role Separation.

### 3.1 Core Workflow: Inverted Application of Test-Driven Refactoring (TDD)

Traditional TDD requires writing tests before code. In AI-assisted refactoring, this process is crucial because it solves the problem of AI "not knowing when to stop".

**Implementation Steps:**

1. **Define Tests (Red):** Before AI starts modifying business logic, require it to first write a test that can reproduce architecture defects or describe new architecture behavior.

    - _Instruction Example:_ "Write an ArchUnit test asserting all `OrderService` dependencies must come from the `OrderDomain` package. Run it, confirm it currently fails."

2. **AI Implementation (Green):** Instruct AI to modify source code, with the sole goal of **making tests pass**.

    - _Constraint:_ AI must not modify test code itself (unless specially authorized).

    - _Advantage:_ This eliminates AI's "free play" space. Test error messages (Compiler Error / Assertion Error) provide AI with precise, deterministic feedback, enabling it to effectively self-correct without relying on hallucination-prone "self-review".

3. **Refactor:** Under test protection, allow AI to optimize code structure.


### 3.2 Legacy System Safety Net: Snapshot Testing

For many legacy projects, writing fine-grained unit tests is very difficult. In this case, **snapshot testing** (or Golden Master Testing) is standard equipment for enterprise large-scale refactoring.

- **Principle:** Don't try to understand the code's internal logic, but capture the system's "input-output" fingerprint. Record all API interfaces, database state, log output current state, save as "snapshot".

- **AI Role:** AI is very good at generating this kind of repetitive characterization test code.

- **Verification Logic:** When performing architecture refactoring (such as moving classes, splitting packages), as long as business logic hasn't changed, snapshot tests should maintain 100% pass. If snapshots fail, it indicates AI accidentally broke business logic during refactoring.

- **Value:** This provides a black-box verification mechanism for "all-AI coders" -- even without looking at code, as long as snapshots haven't changed and architecture tests pass, I can be confident the system has both completed refactoring and not introduced regression errors.


### 3.3 Agent Role Separation: Architects and Craftsmen

In all-AI environments, avoid using the same Chat Session to complete all tasks. Should simulate human team division, building multi-Agent collaboration systems.

|**Agent Role**|**Permissions & Responsibilities**|**Input Restrictions (Critical)**|
|---|---|---|
|**Verification Engineer (Verifier / QA)**|Read-only. Translate design/requirements documents into ArchUnit rules, contract tests, and snapshot baselines. Responsible for running and interpreting test results.|Only allowed to view "Architecture Design Document" or "Requirements Specification", strictly forbidden from viewing Plan documents and source code, to maintain "client acceptance" perspective.|
|**Architecture Planner**|Read-only. Convert design documents into executable implementation steps (Plan.md), and list code modules to touch.|Can view "Design Document" and existing codebase, but cannot access Verifier-generated test content, to avoid "seeing the answer first".|
|**Development Craftsman (Coder)**|Read-write. Implement code per Plan and iterate until all Verifier tests pass; can modify source code and configuration.|Can only reference "Plan Document", test errors, and source code. Forbidden from directly viewing design document original text, preventing implementation and tests from being same-source.|

This separation breaks the "context pollution" of monolithic Agents, ensuring the purity of architecture instructions.

### 3.4 Static Analysis as "Cold Cop"

Since there are no humans for Code Review, **Static Application Security Testing (SAST)** tools stricter than humans must be introduced.

- **Tool Recommendations:** SonarQube (configure Quality Gate), Codacy, Qodo.

- **Strategy:** Set "zero tolerance" policy. If SonarQube finds any new Code Smell, Bug, or security vulnerability, CI pipeline fails directly.

- **Closed Loop:** Feed SonarQube's JSON format report directly to AI Agent. Compared to vague natural language feedback, AI has extremely high repair success rate for SAST reports with clear line numbers and standard error types.


---

## 4. Practical Implementation: Building a "No Code Review" Development Environment

For users' "all-AI coding" scenarios, the following recommends specific tool chain configuration and workflow scripts. This is currently the industry's most advanced **"Agentic IDE"** configuration scheme.

### 4.1 Tool Stack Selection

1. **IDE/Agent:** **Cursor** (with Composer feature) or **Windsurf**. They have multi-file editing and context awareness capabilities.

2. **CLI Automation:** **Aider**. Aider excels in "test-driven loops", supporting automatic test running and error-based fixing.

3. **Architecture Guardian:** **ArchUnit** (Java) / **NetArchTest** (.NET).

4. **Quality Gate:** **SonarQube Cloud** (free version supports open source projects) or local **ESLint/Pylint** (strict rule configuration).


### 4.2 Configure Cursor Rules (`.cursor/rules`)

Create `.cursor/rules` file in project root directory, injecting architecture constraints into every AI interaction. This is equivalent to putting a "tightening spell" on AI.

---

## description: Architecture Refactoring and Quality Red Lines globs: **/_.java, **/_.cs, **/*.ts alwaysApply: true

# Core Principles

1. **Tests First:** Before modifying any business code, must first run `./gradlew test` (or equivalent command). If tests fail, prioritize fixing tests.

2. **Architecture Constraints:**

    - Forbidden to directly call Repository layer from Controller layer.

    - Forbidden to introduce circular dependencies.

    - Any architecture change must pass `ArchitectureTest.java` verification.

3. **Forbidden Behaviors:**

    - Forbidden to delete existing test cases to pass build.

    - Forbidden to use `System.out.println` for debugging, must use logging framework.

4. **Definition of Done:**

    - Only when all unit tests, architecture tests, and static analysis checks (Lint) all pass is the task considered complete.


### 4.3 Aider's Automatic Repair Loop Configuration

For large-scale refactoring, recommend using CLI tool Aider, because it can achieve truly unattended loops.

**Startup Command Example:**

```bash
aider --model sonnet --architect --test-cmd "mvn test && mvn verify"
```

**Workflow Analysis:**

1. **--architect:** Enable architect mode, Aider will think about the plan before generating code, reducing blind trial and error.

2. **--test-cmd:** This is key. Every time Aider modifies code, it automatically runs Maven tests.

    - If tests fail, Aider automatically captures error logs.

    - Aider analyzes errors and attempts new repair rounds without human intervention.

    - This loop continues until tests pass or maximum retry count is reached.

3. **Effect:** This directly replaces users' current "AI fix->AI review" loop, replacing it with deterministic "AI fix->test verification" loop.


---

## 5. Limitations and Risk Warnings

Although the above solutions can significantly reduce risk, the following blind spots still need to be guarded against in "all-AI coding" mode:

1. **Correctness of Tests Themselves:** If AI-generated tests themselves are wrong (e.g.: asserting `1=1` fake tests), the entire verification system fails.

    - _Countermeasure:_ Use **Mutation Testing** tools (such as Pitest). It deliberately modifies business code (introduces bugs) to see if tests can detect them. If tests still pass, test quality is low. Can let AI analyze mutation testing reports to enhance test set.

2. **Requirements Understanding Deviation:** Architecture tests guarantee "structural correctness" but not "business correctness".

    - _Countermeasure:_ Keep high-level acceptance tests or end-to-end tests (E2E) under manual review, or at least have humans confirm consistency between requirements documents and test case descriptions.


---

## 6. Conclusion

The "recursive repair loop" users fall into is not an accidental failure, but an inevitable result of lacking **deterministic feedback mechanisms** in all-AI development mode. The solution is not to optimize Prompts to make AI "review more carefully", but to introduce mathematically verified tools that cannot be "fooled" by AI.

**Final Recommendations for User Questions:**

1. **Immediately stop using AI for "code review".** Invest computational resources in writing **architecture tests (ArchUnit)** and **snapshot tests**.

2. **Build "Red-Green Loop".** Require AI must first see red test failure before writing code.

3. **Embrace tool-based governance.** Use `.cursor/rules` and Aider's `--test-cmd` features to transform "review" actions into automated "test run" actions.


By implementing **Architecture-as-Code** and **Test-Driven Refactoring**, even non-code writers can effectively harness AI to complete complex enterprise architecture refactoring tasks by controlling "rules" and "tests". This role shift from "code writer" to "specification definer" is the inevitable evolution direction of software engineering in the AI era.

---

### Table 1: Verification Strategy Comparative Analysis

|**Verification Dimension**|**Traditional Manual Review**|**AI Review (Current Dilemma)**|**Architecture-as-Code (Recommended)**|
|---|---|---|---|
|**Verification Basis**|Expert experience and intuition|Probability model (Token prediction)|**Deterministic rules (Bytecode/AST)**|
|**Feedback Nature**|Suggestive, vague|Hallucinatory, sycophantic, unstable|**Binary (Pass/Fail), precise**|
|**Coverage Scope**|Sampling inspection (easily fatigued)|Window-limited (easily missed)|**Full scan (100% codebase)**|
|**Loop Convergence**|High|**Non-convergent (infinite loop)**|**High (Red->Green->Refactor)**|
|**Suitable Scenarios**|Core logic, complex algorithms|Simple syntax checks, comment generation|**Architecture dependencies, layer governance, specification enforcement**|

---

## 7. Legacy Code Change Algorithm

> Source: "Working Effectively with Legacy Code" - Michael Feathers

When modifying legacy code, Test Owner must follow this 5-step algorithm, ensuring "test anchors first, then code changes":

### 7.1 Five-Step Process

```
+-----------------------------------------------------------------------+
|  1. Identify      ->  2. Find Test   ->  3. Break    ->  4. Write   ->  5. Change  |
|     Change Point      Point             Dependencies     Tests           Code      |
+-----------------------------------------------------------------------+
```

| Step | Action | Output | Fallback on Failure |
|------|--------|--------|---------------------|
| **1. Identify Change Point** | Locate code position to modify | File:line number list | - |
| **2. Find Test Point** | Identify Pinch Point as test entry point | PP-xxx list | If not found, proceed to step 3 |
| **3. Break Dependencies** | Apply dependency-breaking techniques to make code testable | Seam/Mock points | Reference "Dependency Breaking Techniques Quick Reference" |
| **4. Write Tests** | Write characterization tests at test point, capture current behavior | tests/xxx_test.py | Must Red first then Green |
| **5. Change** | Modify code under test protection | Code changes | Rollback if tests fail |

### 7.2 Pinch Point Priority Principle

**Definition**: Pinch Point is a node where multiple call paths converge; writing tests here can cover the most paths with the fewest tests.

**Identification Method**:
1. Trace call chains outward from change point
2. Find "many-in-one-out" convergence points (functions/classes used by >=2 callers)
3. Prioritize writing tests at Pinch Points, not writing tests for each path

**Example**:
```
Call Chain Analysis:
  ControllerA.handleRequest() --+
  ControllerB.handleBatch()  ---+---> OrderService.processOrder() ---> Repository.save()
  EventHandler.onOrderEvent() --+                ^
                                            [Pinch Point]

Test Strategy:
  X Wrong: Write 1 test each for ControllerA/ControllerB/EventHandler (total 3)
  V Correct: Write only 1 test at OrderService.processOrder() (covers all 3 paths)
```

### 7.3 Test Owner Checklist

Before starting to write tests for legacy code, must answer the following questions:

- [ ] Where is the change point? (file:line number)
- [ ] Where is the Pinch Point? (if cannot identify, need to break dependencies first)
- [ ] Is current code testable? (if not, which dependency-breaking technique is needed?)
- [ ] Does characterization test capture current behavior? (Red first to verify test validity, then Green)
- [ ] Does test count = Pinch Point count? (not call path count)

### 7.4 Sensing and Separation Techniques

When code is "untestable", it's usually because it lacks **Sensing** or **Separation** capability:

| Problem | Symptom | Solution |
|---------|---------|----------|
| **Missing Sensing** | Cannot observe code execution results (e.g.: private methods, no return value, side effects in external systems) | Extract interface, expose test hooks, dependency injection |
| **Missing Separation** | Cannot isolate code under test (e.g.: hardcoded dependencies, global state, static calls) | Parameterize constructor, extract interface, Subclass and Override |

**Core Principles**:
- Sensing = Let tests "see" what code executed
- Separation = Let tests "control" what code depends on

Detailed techniques reference: `dependency-breaking-techniques.md`
