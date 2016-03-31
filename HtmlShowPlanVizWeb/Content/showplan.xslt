<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt"
  xmlns:s="http://schemas.microsoft.com/sqlserver/2004/07/showplan"
  exclude-result-prefixes="msxsl s xsl">

  <xsl:output method="html" indent="no" omit-xml-declaration="yes" />

  <!-- Disable built-in recursive processing templates -->
  <xsl:template match="*|/|text()|@*" mode="NodeLabel2" />
  <xsl:template match="*|/|text()|@*" mode="ShowPlanDetails" />

  <!-- Default template -->
  <xsl:template match="/">
    <xsl:apply-templates select="s:ShowPlanXML" />
  </xsl:template>

  <!-- Outermost div that contains all statement plans. -->
  <xsl:template match="s:ShowPlanXML">
    <div class="query-plan-root">
      <div class="tree">
        <ul class="tree-branch">
          <xsl:apply-templates select="s:BatchSequence/s:Batch/s:Statements/s:StmtSimple" />
        </ul>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="s:StmtSimple">
    <li class="tree-node">
      <div class="query-plan-node">
        <details>
          <summary>
            <header>
              <xsl:apply-templates select="." mode="NodeLabel" />
            </header>
            <xsl:apply-templates select="." mode="NodeLabel2" />
          </summary>
          <div>
            <xsl:call-template name="ShowPlanDetailsGrid" />
            <xsl:apply-templates select="* | @* | */* | */@*" mode="ShowPlanDetails" />
          </div>
        </details>
      </div>
      <xsl:choose>
        <xsl:when test="count(*/s:RelOp) &gt; 0">
          <ul class="tree-branch">
            <xsl:apply-templates select="*/s:RelOp" />
          </ul>
        </xsl:when>
      </xsl:choose>
    </li>
  </xsl:template>

  <!-- Matches a branch in the query plan -->
  <xsl:template match="s:RelOp">
    <li class="tree-node">
      <div class="query-plan-node">
        <details>
          <summary>
            <header>
              <xsl:apply-templates select="." mode="NodeLabel" />
              <xsl:apply-templates select="." mode="NodeCostLabel" />
            </header>
            <xsl:apply-templates select="." mode="NodeLabel2" />
          </summary>
          <div>
            <xsl:call-template name="ShowPlanDetailsGrid" />
            <xsl:apply-templates select="* | @* | */* | */@*" mode="ShowPlanDetails" />
          </div>
        </details>
        <xsl:apply-templates select="." mode="NodeFooterGraph" />
      </div>
      <xsl:choose>
        <xsl:when test="count(*/s:RelOp) &gt; 0">
          <ul class="tree-branch">
            <xsl:apply-templates select="*/s:RelOp" />
          </ul>
        </xsl:when>
      </xsl:choose>
    </li>
  </xsl:template>

  <!-- Writes the grid of node properties to the tool tip -->
  <xsl:template name="ShowPlanDetailsGrid">
    <table>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Condition" select="s:QueryPlan/@CachedPlanSize" />
        <xsl:with-param name="Label">Cached plan size</xsl:with-param>
        <xsl:with-param name="Value" select="concat(s:QueryPlan/@CachedPlanSize, ' B')" />
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Label">Physical Operation</xsl:with-param>
        <xsl:with-param name="Value" select="@PhysicalOp" />
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Label">Logical Operation</xsl:with-param>
        <xsl:with-param name="Value" select="@LogicalOp" />
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Label">Actual Number of Rows</xsl:with-param>
        <xsl:with-param name="Value" select="s:RunTimeInformation/s:RunTimeCountersPerThread/@ActualRows" />
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Condition" select="@EstimateIO" />
        <xsl:with-param name="Label">Estimated I/O Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@EstimateIO" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Condition" select="@EstimateCPU" />
        <xsl:with-param name="Label">Estimated CPU Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@EstimateCPU" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <!-- TODO: Estimated Number of Executions -->
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Label">Number of Executions</xsl:with-param>
        <xsl:with-param name="Value" select="s:RunTimeInformation/s:RunTimeCountersPerThread/@ActualExecutions" />
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Label">Degree of Parallelism</xsl:with-param>
        <xsl:with-param name="Value" select="s:QueryPlan/@DegreeOfParallelism" />
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Label">Memory Grant</xsl:with-param>
        <xsl:with-param name="Value" select="s:QueryPlan/@MemoryGrant" />
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Condition" select="@EstimateIO | @EstimateCPU" />
        <xsl:with-param name="Label">Estimated Operator Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:variable name="EstimatedOperatorCost">
            <xsl:call-template name="EstimatedOperatorCost" />
          </xsl:variable>
          <xsl:variable name="TotalCost">
            <xsl:value-of select="ancestor::s:StmtSimple/@StatementSubTreeCost" />
          </xsl:variable>

          <xsl:call-template name="round">
            <xsl:with-param name="value" select="$EstimatedOperatorCost" />
          </xsl:call-template>
          (<xsl:value-of select="format-number(number($EstimatedOperatorCost) div number($TotalCost), '0%')" />)
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Condition" select="@StatementSubTreeCost | @EstimatedTotalSubtreeCost" />
        <xsl:with-param name="Label">Estimated Subtree Cost</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:call-template name="round">
            <xsl:with-param name="value" select="@StatementSubTreeCost | @EstimatedTotalSubtreeCost" />
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Label">Estimated Number of Rows</xsl:with-param>
        <xsl:with-param name="Value" select="@StatementEstRows | @EstimateRows" />
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Condition" select="@AvgRowSize" />
        <xsl:with-param name="Label">Estimated Row Size</xsl:with-param>
        <xsl:with-param name="Value" select="concat(@AvgRowSize, ' B')" />
      </xsl:call-template>
      <!-- TODO: Actual Rebinds
           TODO: Actual Rewinds -->
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Condition" select="s:IndexScan/@Ordered" />
        <xsl:with-param name="Label">Ordered</xsl:with-param>
        <xsl:with-param name="Value">
          <xsl:choose>
            <xsl:when test="s:IndexScan/@Ordered = 1">True</xsl:when>
            <xsl:otherwise>False</xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="ShowPlanDetailsRow">
        <xsl:with-param name="Label">Node ID</xsl:with-param>
        <xsl:with-param name="Value" select="@NodeId" />
      </xsl:call-template>
    </table>
  </xsl:template>

  <!-- Calculates the estimated operator cost. -->
  <xsl:template name="EstimatedOperatorCost">
    <xsl:variable name="EstimateIO">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="@EstimateIO" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="EstimateCPU">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="@EstimateCPU" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="EstimateRebinds">
      <xsl:choose>
        <xsl:when test="@EstimateRebinds = 0">1</xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="convertSciToNumString">
            <xsl:with-param name="inputVal" select="@EstimateRebinds" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="EstimateRewinds">
      <xsl:choose>
        <xsl:when test="@EstimateRewinds = 0">1</xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="convertSciToNumString">
            <xsl:with-param name="inputVal" select="@EstimateRewinds" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="(number($EstimateIO) + number($EstimateCPU)) * $EstimateRebinds * $EstimateRewinds" />
  </xsl:template>

  <!-- Calculates the estimated operator cost percentage. -->
  <xsl:template name="EstimatedOperatorCostPercentage">
    <xsl:variable name="EstimatedOperatorCost">
      <xsl:call-template name="EstimatedOperatorCost" />
    </xsl:variable>
    <xsl:variable name="TotalCost">
      <xsl:value-of select="ancestor::s:StmtSimple/@StatementSubTreeCost" />
    </xsl:variable>
    <xsl:variable name="Percentage">
      <xsl:choose>
        <xsl:when test="number($EstimatedOperatorCost) div number($TotalCost) > 1">1</xsl:when>
        <xsl:otherwise><xsl:value-of select="number($EstimatedOperatorCost) div number($TotalCost)" /></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="format-number($Percentage, '0%')" />
  </xsl:template>

  <!-- Renders a row in the tool tip details table. -->
  <xsl:template name="ShowPlanDetailsRow">
    <xsl:param name="Label" />
    <xsl:param name="Value" />
    <xsl:param name="Condition" select="$Value" />
    <xsl:if test="$Condition">
      <tr>
        <th>
          <xsl:value-of select="$Label" />
        </th>
        <td>
          <xsl:value-of select="$Value" />
        </td>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- Prints the name of an object. -->
  <xsl:template match="s:Object | s:ColumnReference" mode="ObjectName">
    <xsl:param name="ExcludeDatabaseName" select="false()" />
    <xsl:choose>
      <xsl:when test="$ExcludeDatabaseName">
        <xsl:for-each select="@Table | @Index | @Column | @Alias">
          <xsl:value-of select="." />
          <xsl:if test="position() != last()">.</xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="@Database | @Schema | @Table | @Index | @Column | @Alias">
          <xsl:value-of select="." />
          <xsl:if test="position() != last()">.</xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Displays the node cost label. -->
  <xsl:template match="s:RelOp" mode="NodeCostLabel">

    <xsl:variable name="EstimatedOperatorCostPercentage">
      <xsl:call-template name="EstimatedOperatorCostPercentage" />
    </xsl:variable>
    <span class="node-duration">
      <xsl:value-of select="$EstimatedOperatorCostPercentage" />
    </span>
  </xsl:template>

  <!-- Dont show the node cost for statements. -->
  <xsl:template match="s:StmtSimple" mode="NodeCostLabel" />

  <!-- footer with graph with total cost -->
  <xsl:template match="s:RelOp" mode="NodeFooterGraph">
    <xsl:variable name="EstimatedOperatorCost">
      <xsl:call-template name="EstimatedOperatorCost" />
    </xsl:variable>
    <xsl:variable name="EstimatedOperatorCostPercentage">
      <xsl:call-template name="EstimatedOperatorCostPercentage" />
    </xsl:variable>
    <div class="query-plan-summary-footer">
      <div class="query-plan-node-bar">
        <span class="query-plan-node-bar-fill" style="width: {$EstimatedOperatorCostPercentage}"></span>
      </div>
      <div>
        Cost: <xsl:call-template name="round">
          <xsl:with-param name="value" select="$EstimatedOperatorCost" />
        </xsl:call-template>  | Rows: <xsl:value-of select="@RunTimeInformation/s:RunTimeCountersPerThread/@ActualRows | @StatementEstRows | @EstimateRows" />
      </div>
    </div>
  </xsl:template>

  <!--
  ================================
  Tool tip detail sections
  ================================
  The following section contains templates used for writing the detail sections at the bottom of the tool tip,
  for example listing outputs, or information about the object to which an operator applies.
  -->

  <xsl:template match="*/s:Object" mode="ShowPlanDetails">
    <!-- TODO: Make sure this works all the time -->
    <h4>Object</h4>
    <div>
      <xsl:apply-templates select="." mode="ObjectName" />
    </div>
  </xsl:template>

  <xsl:template match="s:SetPredicate[s:ScalarOperator/@ScalarString]" mode="ShowPlanDetails">
    <h4>Predicate</h4>
    <div>
      <xsl:value-of select="s:ScalarOperator/@ScalarString" />
    </div>
  </xsl:template>

  <xsl:template match="s:OutputList[count(s:ColumnReference) > 0]" mode="ShowPlanDetails">
    <h4>Output List</h4>
    <ul>
      <xsl:for-each select="s:ColumnReference">
        <li>
          <xsl:apply-templates select="." mode="ObjectName" />
        </li>
      </xsl:for-each>
    </ul>
  </xsl:template>

  <xsl:template match="s:NestedLoops/s:OuterReferences[count(s:ColumnReference) > 0]" mode="ShowPlanDetails">
    <h4>Outer References</h4>
    <ul>
      <xsl:for-each select="s:ColumnReference">
        <li>
          <xsl:apply-templates select="." mode="ObjectName" />
        </li>
      </xsl:for-each>
    </ul>
  </xsl:template>

  <xsl:template match="@StatementText" mode="ShowPlanDetails">
    <h4>Statement</h4>
    <pre>
      <xsl:value-of select="." />
    </pre>
  </xsl:template>

  <xsl:template match="s:Sort/s:OrderBy[count(s:OrderByColumn/s:ColumnReference) > 0]" mode="ShowPlanDetails">
    <h4>Order By</h4>
    <ul>
      <xsl:for-each select="s:OrderByColumn">
        <li>
          <xsl:apply-templates select="s:ColumnReference" mode="ObjectName" />
          <xsl:choose>
            <xsl:when test="@Ascending = 1"> Ascending</xsl:when>
            <xsl:otherwise> Descending</xsl:otherwise>
          </xsl:choose>
        </li>
      </xsl:for-each>
    </ul>
  </xsl:template>

  <!-- TODO: Seek Predicates -->

  <!--
  ================================
  Node labels
  ================================
  The following section contains templates used to determine the first (main) label for a node.
  -->

  <xsl:template match="s:RelOp" mode="NodeLabel">
    <h3>
      <xsl:value-of select="@PhysicalOp" />
    </h3>
  </xsl:template>

  <xsl:template match="s:StmtSimple" mode="NodeLabel">
    <h3>
      <xsl:value-of select="@StatementType" />
    </h3>
  </xsl:template>

  <!--
  ================================
  Node alternate labels
  ================================
  The following section contains templates used to determine the second label to be displayed for a node.
  -->

  <!-- Display the object for any node that has one -->
  <xsl:template match="*[*/s:Object]" mode="NodeLabel2">
    <xsl:variable name="ObjectName">
      <xsl:apply-templates select="*/s:Object" mode="ObjectName">
        <xsl:with-param name="ExcludeDatabaseName" select="true()" />
      </xsl:apply-templates>
    </xsl:variable>
    <div>
      <xsl:value-of select="substring($ObjectName, 0, 36)" />
      <xsl:if test="string-length($ObjectName) >= 36">…</xsl:if>
    </div>
  </xsl:template>

  <!-- Display the logical operation for any node where it is not the same as the physical operation. -->
  <xsl:template match="s:RelOp[@LogicalOp != @PhysicalOp]" mode="NodeLabel2">
    <div>
      <xsl:value-of select="@LogicalOp" />
    </div>
  </xsl:template>

  <!-- Disable the default template -->
  <xsl:template match="*" mode="NodeLabel2" />

  <!--
  ================================
  Tool tip descriptions
  ================================
  The following section contains templates used for writing the description shown in the tool tip.
  -->

  <xsl:template match="*[@PhysicalOp = 'Table Insert']" mode="ToolTipDescription">Insert input rows into the table specified in Argument field.</xsl:template>
  <xsl:template match="*[@PhysicalOp = 'Compute Scalar']" mode="ToolTipDescription">Compute new values from existing values in a row.</xsl:template>
  <xsl:template match="*[@PhysicalOp = 'Sort']" mode="ToolTipDescription">Sort the input.</xsl:template>
  <xsl:template match="*[@PhysicalOp = 'Clustered Index Scan']" mode="ToolTipDescription">Scanning a clustered index, entirely or only a range.</xsl:template>
  <xsl:template match="*[@PhysicalOp = 'Stream Aggregate']" mode="ToolTipDescription">Compute summary values for groups of rows in a suitably sorted stream.</xsl:template>
  <xsl:template match="*[@PhysicalOp = 'Hash Match']" mode="ToolTipDescription">Use each row from the top input to build a hash table, and each row from the bottom input to probe into the hash table, outputting all matching rows.</xsl:template>
  <xsl:template match="*[@PhysicalOp = 'Bitmap']" mode="ToolTipDescription">Bitmap.</xsl:template>
  <xsl:template match="*[@PhysicalOp = 'Clustered Index Seek']" mode="ToolTipDescription">Scanning a particular range of rows from a clustered index.</xsl:template>
  <xsl:template match="*[@PhysicalOp = 'Index Seek']" mode="ToolTipDescription">Scan a particular range of rows from a nonclustered index.</xsl:template>

  <xsl:template match="*[@PhysicalOp = 'Parallelism' and @LogicalOp='Repartition Streams']" mode="ToolTipDescription">Repartition Streams.</xsl:template>
  <xsl:template match="*[@PhysicalOp = 'Parallelism']" mode="ToolTipDescription">An operation involving parallelism.</xsl:template>

  <xsl:template match="*[s:TableScan]" mode="ToolTipDescription">Scan rows from a table.</xsl:template>
  <xsl:template match="*[s:NestedLoops]" mode="ToolTipDescription">For each row in the top (outer) input, scan the bottom (inner) input, and output matching rows.</xsl:template>
  <xsl:template match="*[s:Top]" mode="ToolTipDescription">Select the first few rows based on a sort order.</xsl:template>

  <!--
  ================================
  Number handling
  ================================
  The following section contains templates used for handling numbers (scientific notation, rounding etc...)
  -->

  <!-- Outputs a number rounded to 7 decimal places - to be used for displaying all numbers.
  This template accepts numbers in scientific notation. -->
  <xsl:template name="round">
    <xsl:param name="value" select="0" />
    <xsl:variable name="number">
      <xsl:call-template name="convertSciToNumString">
        <xsl:with-param name="inputVal" select="$value" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="round(number($number) * 10000000) div 10000000" />
  </xsl:template>

  <!-- Template for handling of scientific numbers
  See: http://www.orm-designer.com/article/xslt-convert-scientific-notation-to-decimal-number -->
  <xsl:variable name="max-exp">
    <xsl:value-of select="'0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'" />
  </xsl:variable>

  <xsl:template name="convertSciToNumString">
    <xsl:param name="inputVal" select="0" />

    <xsl:variable name="numInput">
      <xsl:value-of select="translate(string($inputVal),'e','E')" />
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="number($numInput) = $numInput">
        <xsl:value-of select="$numInput" />
      </xsl:when>
      <xsl:otherwise>
        <!-- ==== Mantisa ==== -->
        <xsl:variable name="numMantisa">
          <xsl:value-of select="number(substring-before($numInput,'E'))" />
        </xsl:variable>

        <!-- ==== Exponent ==== -->
        <xsl:variable name="numExponent">
          <xsl:choose>
            <xsl:when test="contains($numInput,'E+')">
              <xsl:value-of select="substring-after($numInput,'E+')" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring-after($numInput,'E')" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- ==== Coefficient ==== -->
        <xsl:variable name="numCoefficient">
          <xsl:choose>
            <xsl:when test="$numExponent > 0">
              <xsl:text>1</xsl:text>
              <xsl:value-of select="substring($max-exp, 1, number($numExponent))" />
            </xsl:when>
            <xsl:when test="$numExponent &lt; 0">
              <xsl:text>0.</xsl:text>
              <xsl:value-of select="substring($max-exp, 1, -number($numExponent)-1)" />
              <xsl:text>1</xsl:text>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="number($numCoefficient) * number($numMantisa)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
