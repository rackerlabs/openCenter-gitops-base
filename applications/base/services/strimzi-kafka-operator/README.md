# Strimzi Kafka Operator – Base Configuration

This directory contains the **base manifests** for deploying the
[Strimzi Kafka Operator](https://github.com/strimzi/strimzi-kafka-operator)
to run Apache Kafka on Kubernetes using a Kubernetes-native, operator-driven workflow.

It is intended to be consumed by **cluster repositories** as a remote base,
with the option to provide cluster-specific overrides such as storage classes,
node placement, resource sizing, and exposure methods.

## About Strimzi Kafka Operator

- Provides a Kubernetes operator to deploy and manage **Apache Kafka** and its related components using Custom Resource Definitions (CRDs).
- Manages Kafka lifecycle operations including **scaling, rolling upgrades, configuration changes, and automated reconciliation**.
- Supports Kafka deployment using Kubernetes-native constructs such as **StatefulSets**, Services, and PodDisruptionBudgets.
- Enables secure Kafka clusters with built-in support for **TLS encryption**, authentication (TLS, SCRAM), and authorization patterns.
- Allows Kafka operational resources (topics, users, quotas) to be managed declaratively via **KafkaTopic** and **KafkaUser** CRDs.
- Commonly used to operate **production-grade Kafka on Kubernetes** with consistent configuration and standardized operational practices across environments.
