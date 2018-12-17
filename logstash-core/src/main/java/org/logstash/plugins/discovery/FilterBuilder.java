package org.logstash.plugins.discovery;

import com.google.common.base.Joiner;
import com.google.common.base.Predicate;
import com.google.common.collect.Lists;
import java.util.List;
import java.util.regex.Pattern;

public class FilterBuilder implements Predicate<String> {
    private final List<Predicate<String>> chain;

    public FilterBuilder() {
        chain = Lists.newArrayList();
    }

    /**
     * exclude a regular expression
     */
    public FilterBuilder exclude(final String regex) {
        add(new FilterBuilder.Exclude(regex));
        return this;
    }

    /**
     * add a Predicate to the chain of predicates
     */
    public FilterBuilder add(Predicate<String> filter) {
        chain.add(filter);
        return this;
    }

    /**
     * include a package of a given class
     */
    public FilterBuilder includePackage(final Class<?> aClass) {
        return add(new FilterBuilder.Include(packageNameRegex(aClass)));
    }

    /**
     * include packages of given prefixes
     */
    public FilterBuilder includePackage(final String... prefixes) {
        for (String prefix : prefixes) {
            add(new FilterBuilder.Include(prefix(prefix)));
        }
        return this;
    }

    private static String packageNameRegex(Class<?> aClass) {
        return prefix(aClass.getPackage().getName() + ".");
    }

    public static String prefix(String qualifiedName) {
        return qualifiedName.replace(".", "\\.") + ".*";
    }

    @Override
    public String toString() {
        return Joiner.on(", ").join(chain);
    }

    public boolean apply(String regex) {
        boolean accept = chain == null || chain.isEmpty() || chain.get(0) instanceof FilterBuilder.Exclude;

        if (chain != null) {
            for (Predicate<String> filter : chain) {
                if (accept && filter instanceof FilterBuilder.Include) {
                    continue;
                } //skip if this filter won't change
                if (!accept && filter instanceof FilterBuilder.Exclude) {
                    continue;
                }
                accept = filter.apply(regex);
                if (!accept && filter instanceof FilterBuilder.Exclude) {
                    break;
                } //break on first exclusion
            }
        }
        return accept;
    }

    public abstract static class Matcher implements Predicate<String> {
        final Pattern pattern;

        public Matcher(final String regex) {
            pattern = Pattern.compile(regex);
        }

        public abstract boolean apply(String regex);

        @Override
        public String toString() {
            return pattern.pattern();
        }
    }

    public static class Include extends FilterBuilder.Matcher {
        public Include(final String patternString) {
            super(patternString);
        }

        @Override
        public boolean apply(final String regex) {
            return pattern.matcher(regex).matches();
        }

        @Override
        public String toString() {
            return "+" + super.toString();
        }
    }

    public static class Exclude extends FilterBuilder.Matcher {
        public Exclude(final String patternString) {
            super(patternString);
        }

        @Override
        public boolean apply(final String regex) {
            return !pattern.matcher(regex).matches();
        }

        @Override
        public String toString() {
            return "-" + super.toString();
        }
    }

}
