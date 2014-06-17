package serializables

import java.io.Serializable
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.ksoap2.serialization.KvmSerializable
import org.ksoap2.serialization.SoapObject
import org.ksoap2.serialization.SoapPrimitive

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
		print(clazz.declaredFields.nullOrEmpty)

	addConstructor(clazz,context)

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
						«IF clazz.declaredFields.nullOrEmpty»
						return 0;
							«ELSE»
							return «clazz.declaredFields.size»;
							«ENDIF»
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
						«IF clazz.declaredFields.nullOrEmpty»
						return null;
							«ELSE»
							switch (index){
								«FOR i : 0 .. clazz.declaredFields.size - 1»
									case «i»:	
										return «clazz.declaredFields.toList.get(i).simpleName»;
								«ENDFOR»
							}
							return null;
							«ENDIF»
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
						«IF !clazz.declaredFields.nullOrEmpty»
							switch (arg0){
								«FOR i : 0 .. clazz.declaredFields.size - 1»
									case «i»:	
									arg2.type=«toJavaCode(clazz.declaredFields.toList.get(i).type.wrapperIfPrimitive)».class;
									arg2.name="«clazz.declaredFields.toList.get(i).simpleName.replace('_', '')»";
									break;	
								«ENDFOR»
								default:break;
							}
															«ENDIF»
							
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
								«IF !clazz.declaredFields.nullOrEmpty»

							switch (arg0){
									«FOR i : 0 .. clazz.declaredFields.size - 1»
										«var fieldName = clazz.declaredFields.toList.get(i).simpleName»
										«var fieldType = clazz.declaredFields.toList.get(i).type»
											case «i»:	
											this.«fieldName»=«typeConverted(fieldType.wrapperIfPrimitive, 'arg1')»;
											break;	
									«ENDFOR»
									}
									«ENDIF»
						''']
				]
			}
		}
	}
	
	def addConstructor(MutableClassDeclaration clazz, extension TransformationContext context) {
				clazz.addConstructor [
			addParameter("object", SoapObject.newTypeReference())
			body = [
				'''
					«IF clazz.extendedClass !=Object.newTypeReference()»
					super(object);
					«ENDIF»
«IF !clazz.declaredFields.nullOrEmpty»
					«FOR i : 0 .. clazz.declaredFields.size - 1»
						«val a = clazz.declaredFields.get(i)»
						if(object.hasProperty("«a.simpleName.replace('_', '')»")){
						«toJavaCode(Object.newTypeReference)» obj=object.getProperty("«a.simpleName.replace('_', '')»");
						
						«IF (a.findAnnotation(KsoapObject.newTypeReference().type)==null)»
							if(obj!=null && obj.getClass().equals(SoapPrimitive.class)){
								«toJavaCode(SoapPrimitive.newTypeReference)» value=(SoapPrimitive) obj;
								if(value.toString()!=null){

									this.«a.simpleName»=«typeConverted(a.type.wrapperIfPrimitive, "value")»;
								}
							}else if(obj!=null && obj instanceof «a.type.wrapperIfPrimitive.simpleName»){
								this.«a.simpleName»=(«a.type.wrapperIfPrimitive» ) obj;
								}
								«ELSE»
								this.«a.simpleName»=new «a.type.simpleName»((SoapObject) obj);
						«ENDIF»
						}
					«ENDFOR»
					«ENDIF»

				'''
			]
		]
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
				paramName+".toString().charAt(0)"
			case "byte[]":
				
				"org.kobjects.base64.Base64.decode("+paramName+".toString())"
			
			default:
				"(" + reference.simpleName + ")" + paramName
		}
	}

}
