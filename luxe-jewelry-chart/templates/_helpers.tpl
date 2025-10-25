{{/*
Common labels
*/}}
{{- define "luxe-jewelry.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
Create HPA for a service
*/}}
{{- define "luxe-jewelry.hpa" -}}
{{- $service := index .Values .serviceName }}
{{- if and $service.enabled $service.hpa.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $service.name }}-hpa
  namespace: {{ .Values.global.namespace }}
  labels:
    app: {{ $service.name }}
    {{- include "luxe-jewelry.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $service.name }}
  minReplicas: {{ $service.hpa.minReplicas }}
  maxReplicas: {{ $service.hpa.maxReplicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ $service.hpa.cpuUtilization }}
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: {{ $service.hpa.memoryUtilization }}
{{- end }}
{{- end }}
