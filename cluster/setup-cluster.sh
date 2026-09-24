#!/bin/bash
kind create cluster --name dsys601-lab --config kind-config.yaml
kubectl cluster-info --context kind-dsys601-lab
