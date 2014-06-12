package serializables

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.ksoap2.serialization.KvmSerializable
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.io.Serializable

@Active(typeof(ksoapListSerializableCompilationParticipant))
@Target(ElementType.TYPE)
annotation KsoapListSerializable {
	String nombre = ""
}

class ksoapListSerializableCompilationParticipant extends AbstractClassProcessor {

	override doTransform(MutableClassDeclaration clazz, extension TransformationContext context) {
		if (clazz.extendedClass == Object.newTypeReference()) {
			clazz.annotations.head.addError("Debes extender dde Vector")

		}
		val tipo = clazz.extendedClass.actualTypeArguments.get(0)
		val parameterName = getValue(clazz, context)
		val interfaceUsed = KvmSerializable.newTypeReference
		val serializable = Serializable.newTypeReference()


		clazz.implementedInterfaces = clazz.implementedInterfaces + #[interfaceUsed, serializable]

		val s = interfaceUsed.type as InterfaceDeclaration
		for (method : s.declaredMethods) {

			if (method.simpleName.equalsIgnoreCase("getPropertyCount")) {
				clazz.addMethod(method.simpleName) [
					for (p : method.parameters) {
						addParameter(p.simpleName, p.type)
					}
					returnType = method.returnType
					body = [
						'''
							return this.size();
						''']
				]
			} else if (method.simpleName.equalsIgnoreCase("getProperty")) {
				clazz.addMethod(method.simpleName) [
					for (p : method.parameters) {
						addParameter('index', p.type)
					}
					returnType = method.returnType
					body = [
						'''
							return this.get(index);
						''']
				]
			} else if (method.simpleName.equalsIgnoreCase("getPropertyInfo")) {
				clazz.addMethod(method.simpleName) [
					for (p : method.parameters) {
						addParameter(p.simpleName, p.type)
					}
					returnType = method.returnType
					body = [
						'''
							arg2.name="«parameterName»";
							arg2.type=«toJavaCode(tipo)».class;
						''']
				]
			} else {
				clazz.addMethod(method.simpleName) [
					for (p : method.parameters) {
						addParameter(p.simpleName, p.type)
					}
					returnType = method.returnType
					body = [
						'''
							this.add(«typeConverted(tipo)»);
						''']
				]
			}
		}
	}

	def typeConverted(TypeReference reference) {
		switch (reference.simpleName) {
			case "Boolean":
				"Boolean.parseBoolean(arg1.toString())"
			case "Long":
				"Long.parseLong(arg1.toString())"
			case "Integer":
				"Integer.parseInt(arg1.toString())"
			case "String":
				"arg1.toString()"
			default:
				"(" + reference.simpleName + ")" + " arg1"
		}
	}

	def String getValue(MutableClassDeclaration annotatedClass, extension TransformationContext context) {

		val value = annotatedClass.annotations.findFirst [
			annotationTypeDeclaration == KsoapListSerializable.newTypeReference.type
		].getValue("nombre")

		print(value)
		if(value == null) return null

		return value.toString
	}

}
