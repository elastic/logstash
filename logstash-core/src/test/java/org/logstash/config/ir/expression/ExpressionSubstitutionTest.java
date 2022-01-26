package org.logstash.config.ir.expression;

import com.google.common.collect.ImmutableMap;
import org.junit.Test;
import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.expression.binary.And;
import org.logstash.config.ir.expression.binary.Eq;
import org.logstash.config.ir.expression.binary.Or;
import org.logstash.config.ir.expression.unary.Not;
import org.logstash.plugins.ConfigVariableExpander;

import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.assertEquals;

public class ExpressionSubstitutionTest {

    @Test
    public void basicBinaryBooleanSubstitution() throws InvalidIRException {
        SourceWithMetadata swm = new SourceWithMetadata("proto", "path", 1, 8, "if \"${SMALL}\" == 1 { add_tag => \"pass\" }");
        ValueExpression left = new ValueExpression(swm, "${SMALL}");
        ValueExpression right = new ValueExpression(swm, "1");
        BinaryBooleanExpression expression = new Eq(swm, left, right);

        ConfigVariableExpander cve = getConfigVariableExpander();
        BinaryBooleanExpression substituted = (BinaryBooleanExpression) ExpressionSubstitution.substituteBoolExpression(cve, expression);
        assertEquals(((ValueExpression) substituted.getLeft()).get(), "1");
    }

    @Test
    public void basicUnaryBooleanSubstitution() throws InvalidIRException {
        SourceWithMetadata swm = new SourceWithMetadata("proto", "path", 1, 8, "if !(\"${BIG}\" == 100) { add_tag => \"not\" }");
        ValueExpression valueExp = new ValueExpression(swm, "${BIG}");
        UnaryBooleanExpression expression = new Not(swm, valueExp);

        ConfigVariableExpander cve = getConfigVariableExpander();
        UnaryBooleanExpression substituted = (UnaryBooleanExpression) ExpressionSubstitution.substituteBoolExpression(cve, expression);
        assertEquals(((ValueExpression) substituted.getExpression()).get(), "100");
    }

    @Test
    public void noRegexSubstitution() throws InvalidIRException {
        SourceWithMetadata swm = new SourceWithMetadata("proto", "path", 1, 8, "if [version] =~ /${SMALL}/ { add_tag => \"regex\" }");
        EventValueExpression left = new EventValueExpression(swm, "version");
        RegexValueExpression right = new RegexValueExpression(swm, "${SMALL}");
        BinaryBooleanExpression expression = new Eq(swm, left, right);

        ConfigVariableExpander cve = getConfigVariableExpander();
        BinaryBooleanExpression substituted = (BinaryBooleanExpression) ExpressionSubstitution.substituteBoolExpression(cve, expression);
        assertEquals(substituted.getRight(), expression.getRight());
    }

    @Test
    public void nestedBinaryBooleanSubstitution() throws InvalidIRException {
        SourceWithMetadata swm = new SourceWithMetadata("proto", "path", 1, 8,
                "if \"${SMALL}\" == 1 and 100 == \"${BIG}\" or [version] == 1 { add_tag => \"pass\" }");
        ValueExpression smallLeft = new ValueExpression(swm, "${SMALL}");
        ValueExpression smallRight = new ValueExpression(swm, "1");
        BinaryBooleanExpression smallExp = new Eq(swm, smallLeft, smallRight);

        ValueExpression bigLeft = new ValueExpression(swm, "100");
        ValueExpression bigRight = new ValueExpression(swm, "${BIG}");
        BinaryBooleanExpression bigExp = new Eq(swm, bigLeft, bigRight);

        EventValueExpression versionLeft = new EventValueExpression(swm, "version");
        ValueExpression versionRight = new ValueExpression(swm, "1");
        BinaryBooleanExpression versionExp = new Eq(swm, versionLeft, versionRight);

        And andExp = new And(swm, smallExp, bigExp);
        Or orExp = new Or(swm, andExp, versionExp);

        ConfigVariableExpander cve = getConfigVariableExpander();
        BinaryBooleanExpression substituted = (BinaryBooleanExpression) ExpressionSubstitution.substituteBoolExpression(cve, orExp);
        And subAnd = (And) substituted.getLeft();
        BinaryBooleanExpression subSmallExp = (BinaryBooleanExpression) subAnd.getLeft();
        BinaryBooleanExpression subBigExp = (BinaryBooleanExpression) subAnd.getRight();
        assertEquals(((ValueExpression) subSmallExp.getLeft()).get(), "1");
        assertEquals(((ValueExpression) subBigExp.getRight()).get(), "100");
    }

    public Map<String, String> envVar() {
        return ImmutableMap.of("APP", "foobar", "SMALL", "1", "BIG", "100");
    }

    public ConfigVariableExpander getConfigVariableExpander() {
        return ConfigVariableExpander.withoutSecret(envVar()::get);
    }
}