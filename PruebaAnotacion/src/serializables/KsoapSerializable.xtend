package serializables

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.ksoap2.serialization.KvmSerializable
import java.io.Serializable

@Active(typeof(ksoapSerializableCompilationParticipant))
annotation KsoapSerializable {
}


class ksoapSerializableCompilationParticipant extends AbstractClassProcessor {

	override doRegisterGlobals(ClassDeclaration annotatedClass, extension RegisterGlobalsContext context) {
	}

	override doTransform(MutableClassDeclaration clazz, extension TransformationContext context) {
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
							return �clazz.declaredFields.size�;
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
							switch (index){
								�FOR i : 0 .. clazz.declaredFields.size - 1�
									case �i�:	
										return �clazz.declaredFields.toList.get(i).simpleName�;
								�ENDFOR�
							}
							return null;
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
							switch (arg0){
								�FOR i : 0 .. clazz.declaredFields.size - 1�
									case �i�:	
									arg2.type=�toJavaCode(clazz.declaredFields.toList.get(i).type.wrapperIfPrimitive)�.class;
									arg2.name="�clazz.declaredFields.toList.get(i).simpleName.replace('_', '')�";
									break;	
								�ENDFOR�
								default:break;
							}
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
							switch (arg0){
									�FOR i : 0 .. clazz.declaredFields.size - 1�
										�var fieldName = clazz.declaredFields.toList.get(i).simpleName�
										�var fieldType = clazz.declaredFields.toList.get(i).type�
											case �i�:	
											this.�fieldName�=�typeConverted(fieldType.wrapperIfPrimitive)�;
											break;	
									�ENDFOR�
									}
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

}