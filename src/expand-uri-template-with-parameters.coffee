
ut = require 'uri-template'


expandUriTemplateWithParameters = (uriTemplate, parameters) ->
  result =
    errors: []
    warnings: []
    uri: null

  try
    parsed = ut.parse uriTemplate
  catch e
    text = "\n Failed to parse URI template: #{uriTemplate}"
    text += "\n Error: #{e}"
    result.errors.push text
    return result

  # get parameters from expression object
  uriParameters = []
  for expression in parsed.expressions
    for param in expression.params
      uriParameters.push param.name

  if parsed.expressions.length is 0
    result.uri = uriTemplate
  else
    ambiguous = false

    for uriParameter in uriParameters
      if Object.keys(parameters).indexOf(uriParameter) is -1
        ambiguous = true
        text = "\nAmbiguous URI parameter in template: #{uriTemplate} " + \
               "\nParameter not defined in API description document: " + \
               "'" + uriParameter + "'"
        result.warnings.push text

    unless ambiguous
      toExpand = {}
      for uriParameter in uriParameters
        param = parameters[uriParameter]

        if param.example
          toExpand[uriParameter] = param.example
        else if param.default
          toExpand[uriParameter] = param.default
        else
          if param.required
            ambiguous = true
            result.warnings.push("""\
              Ambiguous URI parameter in template: #{uriTemplate}
              No example value for required parameter in API description \
              document: #{uriParameter}\
            """)

        if param.required and param.default
          result.warnings.push("""\
            Required URI parameter has a default value: #{uriParameter}
            Default value for a required parameter doesn't make sense from \
            API description perspective. Use example value instead.\
          """)

    unless ambiguous
      result.uri = parsed.expand(toExpand)

  return result


module.exports = expandUriTemplateWithParameters
