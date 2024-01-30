#!/usr/bin/env bash

export NAMESPACE=keda
helm install http-add-on kedacore/keda-add-ons-http --namespace ${NAMESPACE}
