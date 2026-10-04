/*
 * Copyright 2015-2026 the original author or authors.
 *
 * All rights reserved. This program and the accompanying materials are
 * made available under the terms of the Eclipse Public License v2.0 which
 * accompanies this distribution and is available at
 * https://www.eclipse.org/legal/epl-v20.html
 *
 * Source-equivalent reflection adaptation of JUnit 6.1.3 KotlinFunctionUtils:
 * keep optional Kotlin interop without a compile-time Kotlin bootstrap.
 */
package org.junit.platform.commons.util;

import static org.junit.platform.commons.util.ExceptionUtils.throwAsUncheckedException;
import static org.junit.platform.commons.util.ReflectionUtils.EMPTY_CLASS_ARRAY;
import static org.junit.platform.commons.util.ReflectionUtils.getUnderlyingCause;

import java.lang.invoke.LambdaConversionException;
import java.lang.invoke.LambdaMetafactory;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.lang.reflect.Type;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import org.jspecify.annotations.Nullable;
import org.junit.platform.commons.JUnitException;

class KotlinFunctionUtils {

    private static Class<?> kotlinClass(String name) {
        try {
            return Class.forName(name, false, KotlinFunctionUtils.class.getClassLoader());
        }
        catch (ClassNotFoundException exception) {
            var error = new NoClassDefFoundError(name.replace('.', '/'));
            error.initCause(exception);
            throw error;
        }
    }

    private static @Nullable Object call(String owner, String name, @Nullable Object receiver,
            Class<?>[] parameterTypes, @Nullable Object... arguments) {
        try {
            return kotlinClass(owner).getMethod(name, parameterTypes).invoke(receiver, arguments);
        }
        catch (InvocationTargetException exception) {
            throw throwAsUncheckedException(exception.getCause());
        }
        catch (NoSuchMethodException exception) {
            var error = new NoSuchMethodError(owner + "." + name + Arrays.toString(parameterTypes));
            error.initCause(exception);
            throw error;
        }
        catch (IllegalAccessException exception) {
            var error = new IllegalAccessError(owner + "." + name);
            error.initCause(exception);
            throw error;
        }
    }

    private static Object getKotlinFunction(Method method) {
        return Preconditions.notNull(call("kotlin.reflect.jvm.ReflectJvmMapping", "getKotlinFunction", null,
                new Class<?>[] { Method.class }, method),
                () -> "Failed to get Kotlin function for method: " + method);
    }

    private static Object getKotlinReturnType(Method method) {
        return call("kotlin.reflect.KCallable", "getReturnType", getKotlinFunction(method), EMPTY_CLASS_ARRAY);
    }

    static Class<?> getReturnType(Method method) {
        var kotlinType = getKotlinReturnType(method);
        var erased = call("kotlin.reflect.jvm.KTypesJvm", "getJvmErasure", null,
                new Class<?>[] { kotlinClass("kotlin.reflect.KType") }, kotlinType);
        var returnType = (Class<?>) call("kotlin.jvm.JvmClassMappingKt", "getJavaClass", null,
                new Class<?>[] { kotlinClass("kotlin.reflect.KClass") }, erased);
        return kotlinClass("kotlin.Unit").equals(returnType) ? void.class : returnType;
    }

    static Type getGenericReturnType(Method method) {
        return (Type) call("kotlin.reflect.jvm.ReflectJvmMapping", "getJavaType", null,
                new Class<?>[] { kotlinClass("kotlin.reflect.KType") }, getKotlinReturnType(method));
    }

    static Parameter[] getParameters(Method method) {
        int count = method.getParameterCount();
        return count == 1 ? new Parameter[0] : Arrays.copyOf(method.getParameters(), count - 1);
    }

    static Class<?>[] getParameterTypes(Method method) {
        int count = method.getParameterCount();
        return count == 1 ? EMPTY_CLASS_ARRAY
                : Arrays.stream(method.getParameterTypes()).limit(count - 1).toArray(Class<?>[]::new);
    }

    private static void makeAccessible(Object function) {
        var signature = new Class<?>[] { kotlinClass("kotlin.reflect.KCallable") };
        if (!(Boolean) call("kotlin.reflect.jvm.KCallablesJvm", "isAccessible", null, signature, function)) {
            call("kotlin.reflect.jvm.KCallablesJvm", "setAccessible", null,
                    new Class<?>[] { signature[0], boolean.class }, function, true);
        }
    }

    private static Map<Object, @Nullable Object> toArgumentMap(@Nullable Object target,
            @Nullable Object[] arguments, Object function) {
        var result = new HashMap<Object, @Nullable Object>(arguments.length + 1);
        int index = 0;
        var parameters = (Iterable<?>) call("kotlin.reflect.KCallable", "getParameters", function,
                EMPTY_CLASS_ARRAY);
        for (Object parameter : parameters) {
            var kind = (Enum<?>) call("kotlin.reflect.KParameter", "getKind", parameter, EMPTY_CLASS_ARRAY);
            switch (kind.name()) {
                case "INSTANCE" -> result.put(parameter, target);
                case "VALUE", "EXTENSION_RECEIVER" -> result.put(parameter, arguments[index++]);
                default -> throw new JUnitException("Unsupported parameter kind: " + kind);
            }
        }
        return result;
    }

    static @Nullable Object invokeKotlinFunction(Method method, @Nullable Object target,
            @Nullable Object[] arguments) {
        Object function = getKotlinFunction(method);
        makeAccessible(function);
        return call("kotlin.reflect.KCallable", "callBy", function,
                new Class<?>[] { Map.class }, toArgumentMap(target, arguments, function));
    }

    private static @Nullable Object invokeSuspendingBlock(Object function, @Nullable Object target,
            @Nullable Object[] arguments, Object scope, Object continuation) {
        try {
            return call("kotlin.reflect.full.KCallables", "callSuspendBy", null,
                    new Class<?>[] { kotlinClass("kotlin.reflect.KCallable"), Map.class,
                            kotlinClass("kotlin.coroutines.Continuation") },
                    function, toArgumentMap(target, arguments, function), continuation);
        }
        catch (Exception exception) {
            throw throwAsUncheckedException(getUnderlyingCause(exception));
        }
    }

    private static Object suspendingBlock(Class<?> function2, Object function, @Nullable Object target,
            @Nullable Object[] arguments) {
        try {
            var lookup = MethodHandles.lookup();
            var implementation = lookup.findStatic(KotlinFunctionUtils.class, "invokeSuspendingBlock",
                    MethodType.methodType(Object.class, Object.class, Object.class, Object[].class,
                            Object.class, Object.class));
            // Match javac's upstream Function2 lambda, not a Proxy: checked
            // exceptions pass through unchanged, including cancellation causes.
            var site = LambdaMetafactory.metafactory(lookup, "invoke",
                    MethodType.methodType(function2, Object.class, Object.class, Object[].class),
                    MethodType.methodType(Object.class, Object.class, Object.class),
                    implementation, MethodType.methodType(Object.class, Object.class, Object.class));
            return site.getTarget().invoke(function, target, arguments);
        }
        catch (LambdaConversionException | ReflectiveOperationException exception) {
            throw new BootstrapMethodError(exception);
        }
        catch (Throwable throwable) {
            throw throwAsUncheckedException(throwable);
        }
    }

    static @Nullable Object invokeKotlinSuspendingFunction(Method method, @Nullable Object target,
            @Nullable Object[] arguments) {
        Object function = getKotlinFunction(method);
        makeAccessible(function);
        Class<?> function2 = kotlinClass("kotlin.jvm.functions.Function2");
        Object block = suspendingBlock(function2, function, target, arguments);
        try {
            Object context = kotlinClass("kotlin.coroutines.EmptyCoroutineContext").getField("INSTANCE").get(null);
            return call("kotlinx.coroutines.BuildersKt", "runBlocking", null,
                    new Class<?>[] { kotlinClass("kotlin.coroutines.CoroutineContext"), function2 }, context, block);
        }
        catch (NoSuchFieldException exception) {
            var error = new NoSuchFieldError("kotlin.coroutines.EmptyCoroutineContext.INSTANCE");
            error.initCause(exception);
            throw error;
        }
        catch (IllegalAccessException exception) {
            var error = new IllegalAccessError("kotlin.coroutines.EmptyCoroutineContext.INSTANCE");
            error.initCause(exception);
            throw error;
        }
    }

    private KotlinFunctionUtils() {
    }
}
