{{- define "petclinic.name" -}}
petclinic
{{- end }}

{{- define "petclinic.fullname" -}}
{{ .Release.Name }}
{{- end }}
