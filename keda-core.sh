#!/usr/bin/env bash

export NAMESPACE=keda
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace ${NAMESPACE} --create-namespace
