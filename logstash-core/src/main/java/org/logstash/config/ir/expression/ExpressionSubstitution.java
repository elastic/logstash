package org.logstash.config.ir.expression;

import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.CompiledPipeline;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.plugins.ConfigVariableExpander;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.Map;

public class ExpressionSubstitution {
    public static Expression substituteBoolExpression(ConfigVariableExpander cve, Expression expression) {
        try {
            if (expression instanceof BinaryBooleanExpression) {
                BinaryBooleanExpression binaryBoolExp = (BinaryBooleanExpression) expression;
                Expression substitutedLeftExp = substituteBoolExpression(cve, binaryBoolExp.getLeft());
                Expression substitutedRightExp = substituteBoolExpression(cve, binaryBoolExp.getRight());
                if (substitutedLeftExp != binaryBoolExp.getLeft() || substitutedRightExp != binaryBoolExp.getRight()) {
                    Constructor<? extends BinaryBooleanExpression> constructor = binaryBoolExp.getClass().getConstructor(SourceWithMetadata.class, Expression.class, Expression.class);
                    return constructor.newInstance(binaryBoolExp.getSourceWithMetadata(), substitutedLeftExp, substitutedRightExp);
                }
            } else if (expression instanceof UnaryBooleanExpression) {
                UnaryBooleanExpression unaryBoolExp = (UnaryBooleanExpression) expression;
                Expression substitutedExp = substituteBoolExpression(cve, unaryBoolExp.getExpression());
                if (substitutedExp != unaryBoolExp.getExpression()) {
                    Constructor<? extends UnaryBooleanExpression> constructor = unaryBoolExp.getClass().getConstructor(SourceWithMetadata.class, Expression.class);
                    return constructor.newInstance(unaryBoolExp.getSourceWithMetadata(), substitutedExp);
                }
            } else if (expression instanceof ValueExpression && !(expression instanceof RegexValueExpression) && (((ValueExpression) expression).get() != null)) {
                String key = "placeholder";
                Map<String, Object> args = Map.of(key, ((ValueExpression) expression).get());
                Map<String, Object> substitutedArgs = CompiledPipeline.expandConfigVariables(cve, args);
                return new ValueExpression(expression.getSourceWithMetadata(), substitutedArgs.get(key));
            }

            return expression;
        } catch (NoSuchMethodException | InstantiationException | IllegalAccessException | InvocationTargetException | InvalidIRException e) {
            throw new IllegalStateException("Unable to instantiate substituted condition expression", e);
        }
    }
}
