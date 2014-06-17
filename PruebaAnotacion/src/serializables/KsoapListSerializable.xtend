package serializables

import java.io.Serializable
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.ksoap2.serialization.KvmSerializable
import org.ksoap2.serialization.SoapObject
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration

@Active(typeof(ksoapListSerializableCompilationParticipant))
@Target(ElementType.TYPE)
annotation KsoapListSerializable {
	String nombre
}

class ksoapListSerializableCompilationParticipant extends AbstractClassProcessor {

	override doTransform(MutableClassDeclaration clazz, extension TransformationContext context) {
		if (clazz.extendedClass == Object.newTypeReference()) {
			clazz.annotations.head.addError("Debes extender de Vector")

		}
		val tipo = clazz.extendedClass.actualTypeArguments.get(0)
		val tipo2 = tipo.type as ClassDeclaration

		val parameterName = getValue(clazz, context)
		val interfaceUsed = KvmSerializable.newTypeReference
		val serializable = Serializable.newTypeReference()

		clazz.implementedInterfaces = clazz.implementedInterfaces + #[interfaceUsed, serializable]

		clazz.addConstructor [
			addParameter("object", SoapObject.newTypeReference())
			body = [
				'''
					int size = object.getPropertyCount();
					 for (int i0=0;i0< size;i0++)
					       {
					           Object obj = object.getProperty(i0);
					           if (obj!=null && obj instanceof «toJavaCode(SoapObject.newTypeReference())»)
					           {
					               SoapObject j =(SoapObject) object.getProperty(i0);
					               «IF tipo2.findAnnotation(KsoapSerializable.newTypeReference().type) != null»
					               	«toJavaCode(tipo)» j1= new «tipo.simpleName»(j);
					               «ELSE»
					               	«toJavaCode(tipo)» j1= «typeConverted(tipo, "j")»;
					               «ENDIF»
					               add(j1);
					           }
					       }
				'''
			]
		]
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
							this.add(«typeConverted(tipo, "arg1")»);
						''']
				]
			}
		}
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

	def String getValue(MutableClassDeclaration annotatedClass, extension TransformationContext context) {

		val value = annotatedClass.annotations.findFirst [
			annotationTypeDeclaration == KsoapListSerializable.newTypeReference.type
		].getValue("nombre")

		if(value == null) return null

		return value.toString
	}

}
