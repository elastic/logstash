/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.config.ir.compiler;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;
import org.jruby.RubyArray;

/**
 * An instance method.
 */
interface MethodSyntaxElement extends SyntaxElement {

    /**
     * Builds a constructor from the given method body and arguments.
     * @param classname Name of the Class
     * @param body Constructor Method Body
     * @return Method Syntax
     */
    static MethodSyntaxElement constructor(final String classname, final Closure body) {
        return new MethodSyntaxElement.MethodSyntaxElementImpl(
            classname, "", body,
            Collections.singletonList(ComputeStepSyntaxElement.CTOR_ARGUMENT)
        );
    }

    /**
     * Builds an implementation of {@link Dataset#clear()} from the given method body.
     * @param body Method Body
     * @return Method Syntax
     */
    static MethodSyntaxElement clear(final Closure body) {
        return new MethodSyntaxElement.MethodSyntaxElementImpl(void.class, "clear", body);
    }

    /**
     * Builds an implementation of {@link Dataset#compute(RubyArray, boolean, boolean)} ()}
     * from the given method body.
     * @param body Method Body
     * @return Method Syntax
     */
    static MethodSyntaxElement compute(final Closure body) {
        return new MethodSyntaxElement.MethodSyntaxElementImpl(
            Collection.class, "compute", body,
            new VariableDefinition(RubyArray.class, DatasetCompiler.BATCH_ARG),
            new VariableDefinition(boolean.class, DatasetCompiler.FLUSH_ARG),
            new VariableDefinition(boolean.class, DatasetCompiler.SHUTDOWN_ARG)
        );
    }

    /**
     * Builds an implementation of {@link SplitDataset#right()} given reference to the else branch's
     * event collection.
     * @param elseData Else Branch's Event Collection Syntax Element
     * @return Method Syntax
     */
    static MethodSyntaxElement right(final ValueSyntaxElement elseData) {
        return new MethodSyntaxElement.MethodSyntaxElementImpl(Dataset.class, "right",
            Closure.wrap(SyntaxFactory.ret(elseData))
        );
    }

    final class MethodSyntaxElementImpl implements MethodSyntaxElement {

        private final String name;

        private final String returnType;

        private final Closure body;

        private final Iterable<VariableDefinition> arguments;

        private MethodSyntaxElementImpl(final Class<?> returnType, final String name,
            final Closure body, final VariableDefinition... arguments) {
            this(returnType.getName(), name, body, Arrays.asList(arguments));
        }

        private MethodSyntaxElementImpl(final String returnType, final String name,
            final Closure body, final Iterable<VariableDefinition> arguments) {
            this.name = name;
            this.returnType = returnType;
            this.arguments = arguments;
            this.body = body;
        }

        @Override
        public String generateCode() {
            return SyntaxFactory.join(
                "public ", returnType, " ", name, "(",
                StreamSupport.stream(arguments.spliterator(), false)
                    .map(VariableDefinition::generateCode).collect(Collectors.joining(",")),
                ") {", body.generateCode(), "}"
            );
        }
    }
}
