package services

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.ksoap2.serialization.SoapObject

@Active(typeof(KsoapServiceCompilationParticipant))
annotation KsoapService {
	String URL
	String NAME_SPACE
	String METHOD_NAME
	String[] inputsParametersNames
	Class[] inputsParametersTypes
}

class KsoapServiceCompilationParticipant extends AbstractClassProcessor {

	override doTransform(MutableClassDeclaration clazz, extension TransformationContext context) {
		createFields(clazz, context)
		createServiceConsumeMethod(clazz, context)
	}

	def createServiceConsumeMethod(MutableClassDeclaration clazz, extension TransformationContext context) {

		clazz.addMethod("Execute") [
			visibility = Visibility.PUBLIC
			returnType = SoapObject.newTypeReference
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
				'''return null;'''
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
}
