# STAGE 1: The "Building" Kitchen
# We start with a full kitchen that has Java's compiler and tools.
FROM openjdk:17-jdk-slim as builder

# Create a clean workspace inside the kitchen called 'app'.
WORKDIR /app

# --- Maven Caching Optimization ---
# Bring in ONLY the recipe list first (pom.xml) and the maven wrapper.
# Docker builds in layers. If these files don't change, Docker reuses the
# next step from its cache, making future builds MUCH faster.
COPY .mvn/ .mvn
COPY mvnw .
COPY pom.xml .

# Read the recipe list and download all "ingredients" (dependencies).
RUN ./mvnw dependency:go-offline

# --- Actual Build ---
# Now that we have all ingredients, bring in the actual source code.
COPY src ./src

# Cook the meal! Compile the code and package it into a single executable JAR file.
# We skip tests because we'll run them in a proper CI/CD pipeline later.
RUN ./mvnw package -DskipTests


# STAGE 2: The "Serving" Box
# We start with a new, smaller, lightweight box that ONLY has the Java runtime.
# It can't compile code, it can only run it. This makes our final box smaller and more secure.
FROM openjdk:17-jdk-slim

# Create a workspace inside the serving box.
WORKDIR /app

# Take the finished, cooked meal (the JAR file) from the "builder" kitchen
# and place it into this final serving box. Rename it to 'app.jar' for simplicity.
COPY --from=builder /app/target/*.jar app.jar

# This is a label on the box telling people what port the service inside listens on.
# For Config Server, it's 8888.
EXPOSE 8761

# The final instruction: When someone "opens" the box, run this command.
# This starts our Spring Boot application.
ENTRYPOINT ["java","-jar","app.jar"]