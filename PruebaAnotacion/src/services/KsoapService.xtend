package services

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.ksoap2.serialization.SoapObject
import org.ksoap2.serialization.PropertyInfo
import org.ksoap2.serialization.SoapSerializationEnvelope
import org.ksoap2.SoapEnvelope
import org.ksoap2.transport.HttpTransportSE
import org.ksoap2.SoapFault
import org.ksoap2.transport.HttpResponseException
import java.io.IOException
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.ksoap2.serialization.SoapPrimitive

@Active(typeof(KsoapServiceCompilationParticipant))
annotation KsoapService {
	String URL
	String NAME_SPACE
	String METHOD_NAME
	String[] inputsParametersNames
	Class<?>[] inputsParametersTypes
	Class<?> typeReturn
}

class KsoapServiceCompilationParticipant extends AbstractClassProcessor {
	var validTypes = #['Boolean', 'Long', 'Integer', 'String', 'Float', 'Double', 'Date', 'byte[]', 'Character']

	override doTransform(MutableClassDeclaration clazz, extension TransformationContext context) {
		createFields(clazz, context)

		createServiceConsumeMethod(clazz, context)
		createServiceMethod(clazz, context)
	}

	def createServiceConsumeMethod(MutableClassDeclaration clazz, extension TransformationContext context) {

		clazz.addMethod("Execute") [
			visibility = Visibility.PUBLIC
			returnType = SoapObject.newTypeReference
			exceptions = #[Exception.newTypeReference()]
			val clases = getArrayClassValue(clazz, context, "inputsParametersTypes")
			val nombres = getArrayStringValue(clazz, context, "inputsParametersNames")
			if (clases.size != nombres.size) {
				clazz.annotations.head.addError(
					"Error parametros no iguales nombres y tipos deben tener la misma dimension")

			}
			for (i : 0 .. clases.size - 1) {

				addParameter(nombres.get(i), clases.get(i))

			}
			body = [
				'''
					«toJavaCode(SoapObject.newTypeReference())» request = new SoapObject(NAME_SPACE,METHOD_NAME);
					«FOR i : 0 .. clases.size - 1»
						«toJavaCode(PropertyInfo.newTypeReference())» propertyInfo«i» = new PropertyInfo();
						propertyInfo«i».setName("«nombres.get(i)»");
						propertyInfo«i».setValue(«nombres.get(i)»);
						propertyInfo«i».setType(«clases.get(i).simpleName».class);
						request.addProperty(propertyInfo«i»);
					«ENDFOR»
					«toJavaCode(SoapSerializationEnvelope.newTypeReference())» envelope = new SoapSerializationEnvelope(«toJavaCode(
						SoapEnvelope.newTypeReference())».VER11);
						//Log.i("REQUEST--->", transp.requestDump)
						//Log.i("RESPONSE--->", transp.responseDump)
					envelope.setOutputSoapObject(request);
					try {
						
						«toJavaCode(HttpTransportSE.newTypeReference())» transp = new HttpTransportSE(URL, 6000);
						transp.debug = true;
						transp.call(NAME_SPACE + METHOD_NAME, envelope);
						Object result = envelope.bodyIn;
						SoapObject _retObject = (SoapObject) result;
						if (result instanceof «toJavaCode(SoapFault.newTypeReference())») {
							SoapFault fault = (SoapFault) result;
							throw new Exception(fault.toString());
							}
						transp.reset();
						return _retObject;
					} catch («toJavaCode(HttpResponseException.newTypeReference())» ex2) {
							//Log.d("spopaerror", "error de conexion")
							throw ex2;
						} catch («toJavaCode(IOException.newTypeReference())» ex) {
							//Log.d("spopaerror", "otro error")
							throw ex;
						}
					
				'''
			]
		]

	}

	def createServiceMethod(MutableClassDeclaration clazz, extension TransformationContext context) {
		val method_name = getStringValue(clazz, context, "METHOD_NAME")
		val returnedType = getClassValue(clazz, context, "typeReturn")
		clazz.addMethod('do' + method_name.toLowerCase.toFirstUpper) [
			visibility = Visibility.PUBLIC
			returnType = returnedType
			exceptions = #[Exception.newTypeReference()]
			val clases = getArrayClassValue(clazz, context, "inputsParametersTypes")
			val nombres = getArrayStringValue(clazz, context, "inputsParametersNames")
			if (clases.size != nombres.size) {
				clazz.annotations.head.addError(
					"Error parametros no iguales nombres y tipos deben tener la misma dimension")

			}
			for (i : 0 .. clases.size - 1) {

				addParameter(nombres.get(i), clases.get(i))

			}
			body = [
				'''
					
					«IF validTypes.contains(returnedType.simpleName)»
						Object rpta=Execute(«nombres.toString.replace('[', '').replace(']', '')»);
						«toJavaCode(SoapPrimitive.newTypeReference)» primitive = (SoapPrimitive) rpta;
						return «typeConverted(returnedType, 'primitive')»;
					«ELSE»
						SoapObject rpta=Execute(«nombres.toString.replace('[', '').replace(']', '')»);
						return new «toJavaCode(returnedType)» (rpta);
					«ENDIF»
				'''
			]
		]
	}

	def createFields(MutableClassDeclaration clazz, extension TransformationContext context) {
		clazz.addField("URL") [
			final = true
			type = String.newTypeReference()
			initializer = ['''"«getStringValue(clazz, context, "URL")»"''']
		]

		clazz.addField("NAME_SPACE") [
			type = String.newTypeReference()
			final = true
			initializer = ['''"«getStringValue(clazz, context, "NAME_SPACE")»"''']
		]
		clazz.addField("METHOD_NAME") [
			final = true
			type = String.newTypeReference()
			initializer = ['''"«getStringValue(clazz, context, "METHOD_NAME")»"''']
		]

	}

	def String getStringValue(MutableClassDeclaration annotatedClass, extension TransformationContext context,
		String propertyName) {

		val value = annotatedClass.annotations.findFirst [
			annotationTypeDeclaration == KsoapService.newTypeReference.type
		].getValue(propertyName)

		if(value == null) return null

		return value.toString
	}

	def String[] getArrayStringValue(MutableClassDeclaration annotatedClass, extension TransformationContext context,
		String propertyName) {

		val value = annotatedClass.annotations.findFirst [
			annotationTypeDeclaration == KsoapService.newTypeReference.type
		].getValue(propertyName)

		if(value == null) return null

		return value as String[]
	}

	def getArrayClassValue(MutableClassDeclaration annotatedClass, extension TransformationContext context,
		String propertyName) {

		val value = annotatedClass.annotations.findFirst [
			annotationTypeDeclaration == KsoapService.newTypeReference.type
		].getClassArrayValue(propertyName)
		if(value == null) return null

		return value
	}

	def TypeReference getClassValue(MutableClassDeclaration annotatedClass, extension TransformationContext context,
		String propertyName) {
		val value = annotatedClass.annotations.findFirst [
			annotationTypeDeclaration == KsoapService.newTypeReference.type
		].getValue(propertyName)

		if(value == null) return null

		return value as TypeReference
	}

	def typeConverted(TypeReference reference, String paramName) {
		switch (reference.simpleName) {
			case "Boolean":
				"Boolean.parseBoolean(" + paramName + ".toString())"
			case "Long":
				"Long.parseLong(" + paramName + ".toString())"
			case "Integer":
				"Integer.parseInt(" + paramName + ".toString())"
			case "String":
				paramName + ".toString()"
			case "Float":
				"Float.parseFloat(" + paramName + ".toString())"
			case "Double":
				"Double.parseDouble(" + paramName + ".toString())"
			case "Date":
				"utils.DatesUtils.parses(" + paramName + ".toString())"
			case "Character":
				paramName + ".toString().charAt(0)"
			case "byte[]":
				"org.kobjects.base64.Base64.decode(" + paramName + ".toString())"
			default:
				"(" + reference.simpleName + ")" + paramName
		}
	}
}
